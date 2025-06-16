defmodule SmalltalkWeb.ConversationsLive.ConversationForm do
  use SmalltalkWeb, :live_component

  alias Smalltalk.Conversations

  @impl true
  def update(assigns, socket) do
    actor = assigns.actor

    socket =
      socket
      |> assign(assigns)
      |> assign(form: conversation_form(actor))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", unsigned_params, socket) do
    form = socket.assigns.form
    params = Map.get(unsigned_params, form.name)
    form = AshPhoenix.Form.validate(form, params)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", unsigned_params, socket) do
    form = socket.assigns.form
    params = Map.get(unsigned_params, form.name)

    socket =
      case AshPhoenix.Form.submit(form, params: params) do
        {:ok, conversation} ->
          redirect_to = socket.assigns[:redirect_to] || ~p"/conversations/#{conversation.id}"

          socket
          |> put_flash(:success, "Conversation created!")
          |> push_navigate(to: redirect_to)

        {:error, errored_form} ->
          assign(socket, form: errored_form)
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Forms.simple_form form={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
        <Forms.text_input field={@form[:short_name]} label="Short Name" />
        <Forms.textarea_input field={@form[:description]} label="Description" />
        <Forms.radio
          field={@form[:type]}
          legend="Conversation Type"
          options={
            Conversations.ConversationType.values()
            |> Enum.map(fn value ->
              {value, Conversations.ConversationType.description(value) || value}
            end)
          }
        />
      </Forms.simple_form>
    </div>
    """
  end

  defp conversation_form(actor) do
    Conversations.form_to_create_conversation(as: "new_conversation", actor: actor) |> to_form()
  end
end
