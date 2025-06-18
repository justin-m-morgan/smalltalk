defmodule SmalltalkWeb.ConversationsLive.Index do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations
  alias SmalltalkWeb.ConversationsLive.ConversationForm
  alias SmalltalkWeb.Components.ConversationList

  require Logger

  @conversation_preloads [participants: [talker: [:full_name, :current_profile_pic_source]]]

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
        preloads: @conversation_preloads
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
        {main_heading(@live_action)}
        <:subtitle>
          {subheading(@live_action)}
        </:subtitle>
        <:actions>
          <ConversationList.display_mode_toggle uri={@uri} current_display_mode={@display_mode} />
          <.new_conversation_modal_trigger />
        </:actions>
      </Containers.header>

      <.live_component
        module={ConversationList}
        id="conversations"
        actor={@actor}
        action={read_action(@live_action, @preloads, @actor)}
        display_mode={String.to_existing_atom(@display_mode)}
      />

      <Modal.container id="new_conversation_modal">
        <.live_component id="new_conversation_form" module={ConversationForm} actor={@actor} />
      </Modal.container>
    </Layouts.app>
    """
  end

  def main_heading(:search), do: "Search for conversations"
  def main_heading(_), do: "My Conversations"

  def subheading(:public), do: "Publicly accessible conversations"
  def subheading(:private), do: "Conversations you've been accepted into"
  def subheading(:secret), do: "Conversations only available by invite"

  def subheading(:awaiting_approval),
    do: "Private conversations still requiring approval by an admin"

  def subheading(:is_admin),
    do: "Private conversations you are an admin for"

  def subheading(:search),
    do: "Find new conversations to join"

  def read_action(:public, preloads, actor) do
    {Conversations, :participants_by_actor!,
     [
       actor: actor,
       path_to_conversation: [:conversation],
       load: [conversation: preloads],
       query: [filter: [conversation: [type: :public]]]
     ]}
  end

  def read_action(:private, preloads, actor) do
    {Conversations, :participants_by_actor!,
     [
       actor: actor,
       path_to_conversation: [:conversation],
       load: [conversation: preloads],
       query: [filter: [conversation: [type: :private]]]
     ]}
  end

  def read_action(:secret, preloads, actor) do
    {Conversations, :participants_by_actor!,
     [
       actor: actor,
       path_to_conversation: [:conversation],
       load: [conversation: preloads],
       query: [filter: [conversation: [type: :secret]]]
     ]}
  end

  def read_action(:awaiting_approval, preloads, actor) do
    {Conversations, :participants_by_actor!,
     [
       actor: actor,
       path_to_conversation: [:conversation],
       load: [conversation: preloads],
       query: [
         filter: [
           awaiting_approval?: true
         ]
       ]
     ]}
  end

  def read_action(:is_admin, preloads, actor) do
    {Conversations, :admins_by_actor!,
     [
       actor: actor,
       path_to_conversation: [:conversation],
       load: [conversation: preloads]
     ]}
  end

  def read_action(:search, preloads, actor) do
    {Conversations, :get_conversations!,
     [
       query: [filter: [type: [not: [:secret]]]],
       path_to_conversation: [],
       load: preloads,
       actor: actor
     ]}
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
