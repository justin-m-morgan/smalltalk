defmodule SmalltalkWeb.ConversationsLive.Index do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations

  require Logger

  @preloads [participants: [talker: [:full_name, :current_profile_pic_source]]]

  @impl true
  def handle_params(params, _session, socket) do
    actor = socket.assigns.talker

    form = new_conversation_form(actor)

    conversation_id = Map.get(params, "conversation_id")

    socket =
      socket
      |> assign(actor: actor, conversation_id: conversation_id, new_conversation_form: form)
      |> stream_async(:conversations, fn ->
        Conversations.get_my_conversations!(load: @preloads, actor: actor)
      end)

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
            Conversations.get_conversation!(conversation_id, load: @preloads, actor: actor)

          socket
          |> stream_delete(:conversations, conversation)
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
      active_sub_tab={:mine}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        Find New Conversations
        <:subtitle>
          Search conversations by keyword or user.
        </:subtitle>
      </Containers.header>

      <.async_result :let={stream_key} assign={@conversations}>
        <:loading>Loading...</:loading>
        <:failed>Failed to load conversations.</:failed>

        <div class="grid grid-cols-3 gap-4" phx-update="stream" id="my-conversations-stream">
          <.conversation_card
            :for={{dom_id, conversation} <- @streams[stream_key]}
            id={dom_id}
            conversation={conversation}
          />
        </div>

        <div class="flex justify-center py-8">
          <.new_conversation_modal_trigger />
        </div>
      </.async_result>

      <Modal.container id="new_conversation_modal">
        <Forms.simple_form form={@new_conversation_form} phx-change="validate" phx-submit="save">
          <Forms.text_input field={@new_conversation_form[:short_name]} label="Short Name" />
          <Forms.textarea_input field={@new_conversation_form[:description]} label="Description" />
        </Forms.simple_form>
      </Modal.container>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :conversation, Conversations.Conversation, required: true

  def conversation_card(assigns) do
    ~H"""
    <Containers.card id={@id} container_class="bg-base-200">
      <Containers.list>
        <:item title="Short Name">{@conversation.short_name}</:item>
        <:item title="Participants">
          <DataBlocks.avatar_group data={@conversation.participants}>
            <:avatar_template :let={participant}>
              <DataBlocks.avatar
                src={participant.talker.current_profile_pic_source}
                image_type={:thumbnail}
                alt_text={"#{participant.talker.full_name}"}
              />
            </:avatar_template>
          </DataBlocks.avatar_group>
        </:item>
        <:item title="Description">{@conversation.description}</:item>
      </Containers.list>
      <:actions>
        <.action_button
          label="Leave"
          phx-click="leave_conversation"
          conversation_id={@conversation.id}
        />
        <.action_button
          label="Go To"
          navigate={~p"/conversations/#{@conversation.id}"}
          conversation_id={@conversation.id}
        />
      </:actions>
    </Containers.card>
    """
  end

  attr :label, :string, required: true
  attr :conversation_id, :string, required: true
  attr :rest, :global, include: ~w/navigate phx-click/

  defp action_button(assigns) do
    ~H"""
    <Button.button type="button" size="btn-sm" phx-value-conversation_id={@conversation_id} {@rest}>
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

  defp new_conversation_form(actor) do
    Conversations.form_to_create_conversation(as: "new_conversation", actor: actor) |> to_form()
  end
end
