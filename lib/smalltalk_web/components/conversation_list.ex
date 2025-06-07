defmodule SmalltalkWeb.Components.ConversationList do
  use SmalltalkWeb, :live_component
  use LiveStreamAsync

  alias Smalltalk.Conversations

  require Logger

  @impl true
  def update(assigns, socket) do
    actor = assigns.actor
    action = assigns.action
    preloads = assigns[:preloads] || []

    socket =
      socket
      |> assign(actor: actor, preloads: preloads)
      |> then(&assign(&1, new_conversation_form: new_conversation_form(&1)))
      |> stream_async(:conversations, fn ->
        apply(Conversations, action, [%{}, %{load: preloads, actor: actor}])
      end)

    {:ok, socket}
  end

  @impl true
  @spec handle_event(<<_::32, _::_*8>>, map(), any()) :: {:noreply, any()}
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
    preloads = socket.assigns.preloads

    socket =
      case Conversations.leave_conversation(conversation_id, actor: actor) do
        :ok ->
          conversation =
            Conversations.get_conversation!(conversation_id, load: preloads, actor: actor)

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
    <div>
      <Containers.header>
        Find New Conversations
        <:subtitle>
          Search conversations by keyword or user.
        </:subtitle>
      </Containers.header>

      <.async_result :let={stream_key} assign={@conversations}>
        <:loading>Loading...</:loading>
        <:failed>Failed to load conversations.</:failed>

        <.table target={@myself} rows={@streams[stream_key]} actor_id={@actor.id}>
          <:modal_trigger>
            <.new_conversation_modal_trigger />
          </:modal_trigger>
        </.table>

        <div class="flex justify-center py-8">
          <.new_conversation_modal_trigger />
        </div>
      </.async_result>

      <Modal.container id="new_conversation_modal">
        <Forms.simple_form
          form={@new_conversation_form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <Forms.text_input field={@new_conversation_form[:short_name]} label="Short Name" />
          <Forms.textarea_input field={@new_conversation_form[:description]} label="Description" />
        </Forms.simple_form>
      </Modal.container>
    </div>
    """
  end

  attr :actor_id, :string, required: true
  attr :target, :any, default: nil
  attr :rows, Phoenix.LiveView.LiveStream, required: true
  slot :modal_trigger, required: true

  defp table(assigns) do
    ~H"""
    <Table.table id="conversations" rows={@rows}>
      <:col :let={{_id, conversation}} label="Short Name">{conversation.short_name}</:col>
      <:col :let={{_id, conversation}} label="Description">{conversation.description}</:col>
      <:action :let={{_dom_id, conversation}}>
        <%= if @actor_id in Enum.map(conversation.participants, & &1.talker_id) do %>
          <Button.button
            type="button"
            size="btn-sm"
            phx-target={@target}
            navigate={~p"/conversations?conversation_id=#{conversation.id}"}
          >
            Go To
          </Button.button>
          <Button.button
            type="button"
            size="btn-sm"
            phx-target={@target}
            phx-click="leave_conversation"
            phx-value-conversation_id={conversation.id}
          >
            Leave
          </Button.button>
        <% else %>
          <Button.button
            type="button"
            size="btn-sm"
            phx-target={@target}
            phx-click="join_conversation"
            phx-value-conversation_id={conversation.id}
          >
            Join
          </Button.button>
        <% end %>
      </:action>
      <:empty_results>
        <div class="flex flex-col items-center gap-16">
          <span>No Conversations</span>
          {render_slot(@modal_trigger)}
        </div>
      </:empty_results>
    </Table.table>
    """
  end

  attr :label, :string, required: true
  attr :click_event, :any, required: true
  attr :conversation_id, :string, required: true
  attr :rest, :global, include: ~w/navigate/

  defp action_button(assigns) do
    ~H"""
    <Button.button
      type="button"
      size="btn-sm"
      phx-target={@target}
      phx-click={@click_event}
      phx-value-conversation_id={@conversation_id}
    >
      {@label}
    </Button.button>
    """
  end

  defp new_conversation_modal_trigger(assigns) do
    ~H"""
    <Button.button phx-click={Modal.show_modal("new_conversation_modal")} size="btn-xl">
      Start a New Conversation
    </Button.button>
    """
  end

  defp new_conversation_form(socket) do
    actor = socket.assigns.actor
    Conversations.form_to_create_conversation(as: "new_conversation", actor: actor) |> to_form()
  end
end
