defmodule SmalltalkWeb.ConversationsLive.Search do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations
  alias SmalltalkWeb.Components.ConversationList

  require Logger

  @preloads [participants: [talker: [:full_name, :current_profile_pic_source]]]

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker
    form = new_conversation_form(actor)

    socket =
      socket
      |> assign(actor: actor, new_conversation_form: form)
      |> stream_async(:conversations, fn ->
        Conversations.get_conversations!(actor: actor, load: @preloads)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    display_mode = Map.get(params, "display_mode", "cards")

    socket =
      socket
      |> assign(display_mode: display_mode, uri: uri)

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
          |> assign(new_conversation_form: new_conversation_form(socket))
          |> stream_insert(:conversations, conversation)
          |> put_flash(:success, "Conversation created!")

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
            Conversations.get_conversation!(conversation_id, load: @preloads, actor: actor)

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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:conversations}
      active_sub_tab={:search_for_new}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        Find New Conversations
        <:subtitle>
          Search conversations by keyword or user.
        </:subtitle>
        <:actions>
          <ConversationList.display_mode_toggle current_display_mode={@display_mode} uri={@uri} />
          <.new_conversation_modal_trigger />
        </:actions>
      </Containers.header>

      <.live_component
        module={ConversationList}
        id="conversations"
        actor={@actor}
        action={
          {Conversations, :get_conversations!,
           [
             query: [filter: [type: [not: [:secret]]]],
             load: [participants: [talker: [:full_name, :current_profile_pic_source]]]
           ]}
        }
        display_mode={String.to_existing_atom(@display_mode)}
      />

      <Modal.container id="new_conversation_modal">
        <Forms.simple_form form={@new_conversation_form} phx-change="validate" phx-submit="save">
          <Forms.text_input field={@new_conversation_form[:short_name]} label="Short Name" />
          <Forms.textarea_input field={@new_conversation_form[:description]} label="Description" />
        </Forms.simple_form>
      </Modal.container>
    </Layouts.app>
    """
  end

  def display_mode_toggle(assigns) do
    next_display_mode = if assigns.current_display_mode == "table", do: "cards", else: "table"
    checked = assigns.current_display_mode == "cards"

    assigns =
      assign(assigns,
        patch: ~p[/conversations/search?display_mode=#{next_display_mode}],
        checked: checked
      )

    ~H"""
    <label class="toggle toggle-xl h-full w-18 text-base-content" phx-click={JS.patch(@patch)}>
      <input type="checkbox" checked={@checked} />
      <Icon.icon name="hero-list-bullet" class="size-8" />
      <Icon.icon name="hero-square-2-stack" class="size-8" />
    </label>
    """
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
end
