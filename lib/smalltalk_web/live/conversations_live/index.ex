defmodule SmalltalkWeb.ConversationsLive.Index do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations
  alias SmalltalkWeb.ConversationsLive.ConversationForm

  alias SmalltalkWeb.Components.EasyTable

  require Logger

  @conversation_preloads [
    :is_admin?,
    :approved?,
    :awaiting_approval?,
    :status,
    participants: [talker: [:full_name, :current_profile_pic_source]]
  ]

  @impl true
  def handle_params(params, uri, socket) do
    actor = socket.assigns.talker
    display_mode = Map.get(params, "display_mode", "cards")

    form = new_conversation_form(actor)

    conversation_id = Map.get(params, "conversation_id")

    socket =
      socket
      |> assign(
        uri: uri,
        actor: actor,
        conversation_id: conversation_id,
        new_conversation_form: form,
        display_mode: display_mode,
        preloads: @conversation_preloads,
        action: read_action(socket.assigns.live_action, %{actor: actor})
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", unsigned_params, socket) do
    form = socket.assigns.new_conversation_form
    params = Map.get(unsigned_params, form.name)
    form = AshPhoenix.Form.validate(form, params)

    {:noreply, assign(socket, :new_conversation_form, form)}
  end

  def handle_event("save", unsigned_params, socket) do
    form = socket.assigns.new_conversation_form
    params = Map.get(unsigned_params, form.name)

    socket =
      case AshPhoenix.Form.submit(form, params: params) do
        {:ok, conversation} ->
          socket
          |> put_flash(:success, "Conversation created!")
          |> push_navigate(to: ~p"/conversations/#{conversation.id}")

        {:error, errored_form} ->
          assign(socket, new_conversation_form: errored_form)
      end

    {:noreply, socket}
  end

  def handle_event("join_conversation", %{"conversation_id" => conversation_id}, socket) do
    actor = socket.assigns.actor

    socket =
      case Conversations.join_conversation(conversation_id, actor: actor) do
        {:ok, _participants} ->
          socket
          |> push_navigate(to: ~p"/conversations?conversation_id=#{conversation_id}")
          |> put_flash(:success, "You joined the conversation!")

        {:error, error} ->
          Logger.error(error)

          socket
          |> put_flash(:error, "Error joining conversation.")
      end

    {:noreply, socket}
  end

  def handle_event(
        "leave_conversation",
        %{"conversation_id" => conversation_id},
        socket
      ) do
    actor = socket.assigns.actor

    socket =
      case Conversations.leave_conversation(conversation_id, actor: actor) do
        :ok ->
          conversation =
            Conversations.get_conversation!(conversation_id,
              load: @conversation_preloads,
              actor: actor
            )

          socket
          |> stream_insert(:conversations, conversation)
          |> put_flash(:success, "You have left the conversation!")

        {:error, error} ->
          Logger.error(error)

          socket
          |> put_flash(:error, "Error leaving conversation.")
      end

    {:noreply, socket}
  end

  attr :conversation_preloads, :list, default: @conversation_preloads
  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:conversations}
      active_sub_tab={@live_action}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        {@action[:main_heading] || "My Conversations"}
        <:subtitle>
          {@action[:subheading]}
        </:subtitle>
        <:actions>
          <.new_conversation_modal_trigger />
        </:actions>
      </Containers.header>

      <.live_component
        id="conversation-table"
        module={EasyTable}
        resource={Conversations.Conversation}
        display_mode="cards"
        fixed_width_columns?={false}
        read_action={@action[:read_action] || :mine}
        opts={[actor: @talker, load: @conversation_preloads, filter: @action[:filter]]}
        default_sort={{:short_name, :asc}}
        actor={@talker}
        striped?={true}
        limit={15}
        searchable_fields={[:short_name, :description]}
        size="table-xl"
        filters={[
          type: %{
            filter: %{field: :type, operation: :in},
            options:
              Enum.map(
                Conversations.ConversationType.values(),
                &{&1, Phoenix.Naming.humanize(&1)}
              ),
            kind: :checkbox_group,
            default: [:public, :private, :secret]
          },
          is_admin?: %{
            filter: %{field: :is_admin?, operation: :in},
            options: [true: "Yes", false: "No"],
            kind: :checkbox_group,
            default: [true, false]
          },
          status: %{
            filter: %{field: :status, operation: :in},
            options:
              Enum.map([:approved, :rejected, :awaiting_approval], &{&1, Phoenix.Naming.humanize(&1)}),
            kind: :checkbox_group,
            default: [:approved, :rejected, :awaiting_approval]
          }
        ]}
      >
        <:caption>
          Conversations
        </:caption>

        <:col :let={conversation} label="Short Name" sort_key={:short_name}>
          {conversation.short_name}
        </:col>
        <:col :let={conversation} label="Status">
          <Icon.icon :if={conversation.status == :approved} name="hero-check-circle" class="size-6" />
          <Icon.icon
            :if={conversation.status == :rejected}
            name="hero-hand-thumb-down"
            class="size-6"
          />
          <Icon.icon :if={conversation.status == :awaiting_approval} name="hero-clock" class="size-6" />
          <Icon.icon :if={conversation.is_admin?} name="hero-key" class="size-6" />
        </:col>

        <:col :let={conversation} label="Type" sort_key={:type}>
          <.conversation_type_badge type={conversation.type} />
        </:col>

        <:col :let={conversation} label="Participants">
          <DataBlocks.avatar_group data={conversation.participants}>
            <:avatar_template :let={participant}>
              <DataBlocks.avatar
                size="size-8"
                src={participant.talker.current_profile_pic_source}
                image_type={:thumbnail}
                alt_text={"#{participant.talker.full_name}"}
              />
            </:avatar_template>
          </DataBlocks.avatar_group>
        </:col>
        <:action :let={{_dom_id, conversation}}>
          <.action_button
            :for={action <- actions(%{conversation: conversation, actor: @actor})}
            phx-value-conversation_id={conversation.id}
            {action}
          />
        </:action>
      </.live_component>

      <Modal.container id="new_conversation_modal">
        <.live_component id="new_conversation_form" module={ConversationForm} actor={@actor} />
      </Modal.container>
    </Layouts.app>
    """
  end

  def read_action(:mine, _deps) do
    %{
      filter: [],
      subheading: "All my conversations"
    }
  end

  def read_action(:search, _deps) do
    %{
      read_action: :read,
      filter: [],
      main_heading: "Search for conversations",
      subheading: "Find new conversations to join"
    }
  end

  def actions(deps \\ %{}) do
    cond do
      deps.actor.id in Enum.map(deps.conversation.participants, & &1.talker_id) ->
        [
          %{label: "Go To", navigate: ~p"/conversations?conversation_id=#{deps.conversation.id}"},
          %{label: "Leave", "phx-click": "leave_conversation"}
        ]

      true ->
        [
          %{label: "Join", "phx-click": "join_conversation"}
        ]
    end
  end

  defp new_conversation_modal_trigger(assigns) do
    ~H"""
    <Button.button phx-click={Modal.show_modal("new_conversation_modal")} size="btn-xl">
      Start a New Conversation
    </Button.button>
    """
  end

  defp new_conversation_form(actor) do
    Conversations.form_to_create_conversation(as: "new_conversation", actor: actor) |> to_form()
  end

  attr :type, :atom, values: Conversations.ConversationType.values()

  defp conversation_type_badge(assigns) do
    ~H"""
    <Indicators.badge color={Conversations.ConversationType.badge_color(@type)}>
      {Phoenix.Naming.humanize(@type)}
    </Indicators.badge>
    """
  end

  attr :label, :string, required: true

  attr :rest, :global, include: ~w/navigate phx-click phx-target phx-value-conversation_id/

  defp action_button(assigns) do
    ~H"""
    <Button.button type="button" size="btn-sm" {@rest}>
      {@label}
    </Button.button>
    """
  end
end
