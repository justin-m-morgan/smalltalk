defmodule SmalltalkWeb.ConversationsLive.Chat.InputLive do
  use SmalltalkWeb, :live_component

  alias Smalltalk.Conversations

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(form: form(assigns.actor, %{content: ""}))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_message_form", params, socket) do
    params = Map.get(params, socket.assigns.form.name)
    original_form = socket.assigns.form

    form = AshPhoenix.Form.validate(original_form, params)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("send_message", params, socket) do
    actor = socket.assigns.actor
    params = Map.get(params, socket.assigns.form.name)
    original_form = socket.assigns.form
    # topic = socket.assigns.new_messages_topic

    socket =
      case AshPhoenix.Form.submit(original_form, params: params) do
        {:ok, _message} ->
          socket
          |> assign(:form, form(actor, %{content: ""}))

        {:error, form} ->
          assign(socket, form: form)
      end

    {:noreply, socket}
  end

  attr :conversation_id, :string, required: true
  attr :form, Phoenix.HTML.Form, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4 flex">
      <Forms.simple_form
        id="new-message-form"
        form={@form}
        class="flex justify-between gap-2 grow-1"
        actions_container_classes="h-full"
        phx-target={@myself}
        phx-submit="send_message"
        phx-change="validate_message_form"
        submit_button_size="h-full btn-xl"
      >
        <input type="hidden" name={@form[:conversation_id].name} value={@conversation_id} />
        <Forms.textarea_input
          phx-debounce="1000"
          type="textarea"
          rows={5}
          field={@form[:content]}
          container_class="w-full"
        />

        <:submit_button>
          <Icon.icon name="hero-paper-airplane-solid" class="size-12" />
        </:submit_button>
      </Forms.simple_form>
    </div>
    """
  end

  defp form(actor, params, _conversation_id \\ nil) do
    # TODO: integrate conversation_id into form rather than casting
    [params: params, actor: actor, as: "send_message"]
    |> Conversations.form_to_send_message()
    |> to_form()
  end
end
