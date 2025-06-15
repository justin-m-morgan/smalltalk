defmodule SmalltalkWeb.ConversationsLive.Chat.AdminPanelLive do
  use SmalltalkWeb, :live_component
  use LiveStreamAsync

  alias Smalltalk.Conversations
  alias SmalltalkWeb.ConversationsLive.Chat

  @impl true
  def update(assigns, socket) do
    actor = assigns.actor
    conversation_id = assigns.conversation_id

    socket =
      socket
      |> assign(assigns)
      |> assign(block_event: "block?")
      |> stream_async(:admins, fn ->
        Conversations.admins_for_conversation!(
          conversation_id,
          load: [talker: [:full_name, :current_profile_pic_source]],
          actor: actor
        )
      end)
      |> stream_async(:blocked, fn ->
        Conversations.participants_blocked!(
          conversation_id,
          load: [talker: [:full_name, :current_profile_pic_source]],
          actor: actor
        )
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event(event, %{"participant_id" => participant_id}, socket)
      when event == socket.assigns.block_event do
    actor = socket.assigns.actor
    conversation_id = socket.assigns.conversation_id

    dbg(actor)

    Conversations.get_participant!(participant_id, actor: actor)
    |> Conversations.unblock_participant!(%{}, actor: actor)

    socket =
      stream_async(
        socket,
        :blocked,
        fn ->
          Conversations.participants_blocked!(
            conversation_id,
            load: [talker: [:full_name, :current_profile_pic_source]],
            actor: actor
          )
        end,
        replace: true
      )

    {:noreply, socket}
  end

  attr :active_panel, :atom, required: true
  attr :admins, Phoenix.LiveView.AsyncResult, required: true
  attr :blocked, Phoenix.LiveView.AsyncResult, required: true
  attr :block_event, :string, required: true
  attr :streams, :map, required: true

  def render(assigns) do
    ~H"""
    <div>
      <Chat.ConversationSidebar.panel id="admin" title="Admin Overview">
        <Button.button navigate={~p[/conversations/#{@conversation_id}/admin]}>
          <span>Admin Page for Conversation</span>
          <Icon.icon name="hero-arrow-right" class="size-6" />
        </Button.button>
        <.async_result :let={stream_key} assign={@admins}>
          <:loading>Loading Admins</:loading>
          <:failed>Failed to Load Admins</:failed>
          <div class="grid gap-4">
            <.admins participants={@streams[stream_key]} />
          </div>
        </.async_result>
        <.async_result :let={stream_key} assign={@blocked}>
          <:loading>Loading Blocked Participants</:loading>
          <:failed>Failed to Load Blocked Participants</:failed>
          <.blocked_participants
            target={@myself}
            block_event={@block_event}
            participants={@streams[stream_key]}
          />
        </.async_result>
      </Chat.ConversationSidebar.panel>
    </div>
    """
  end

  attr :participants, :list, required: true

  @spec admins(map()) :: Phoenix.LiveView.Rendered.t()
  def admins(assigns) do
    ~H"""
    <div class="grid gap-4">
      <Chat.ConversationSidebar.participant_group id="admin-stream" participants={@participants}>
        <:label>Admins</:label>
      </Chat.ConversationSidebar.participant_group>
    </div>
    """
  end

  attr :target, :any, required: true
  attr :participants, :list, required: true
  attr :block_event, :string, required: true

  def blocked_participants(assigns) do
    ~H"""
    <div class="grid gap-4">
      <Chat.ConversationSidebar.participant_group id="admin-stream" participants={@participants}>
        <:label>Blocked</:label>
        <:actions :let={participant}>
          <Button.button
            phx-target={@target}
            phx-click={@block_event}
            phx-value-participant_id={participant.id}
            phx-value-block={false}
            size="btn-xs"
          >
            Unblock
          </Button.button>
        </:actions>
      </Chat.ConversationSidebar.participant_group>
    </div>
    """
  end
end
