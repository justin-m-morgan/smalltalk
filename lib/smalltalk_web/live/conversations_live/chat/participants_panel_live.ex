defmodule SmalltalkWeb.ConversationsLive.Chat.ParticipantsPanelLive do
  use SmalltalkWeb, :live_component
  use LiveStreamAsync

  alias Smalltalk.Conversations
  alias SmalltalkWeb.ConversationsLive.Chat
  alias SmalltalkWeb.Presence

  @talker_preloads [:full_name, :current_profile_pic_source]

  @impl true
  def update(%{presence: {:join, presence}}, socket) do
    conversation_id = socket.assigns.conversation_id
    actor = socket.assigns.actor
    presence_topic = socket.assigns.presence_topic

    socket =
      socket
      |> stream_insert(:presences, presence.user)
      |> stream_async(
        :offline_participants,
        fn ->
          compute_offline_participants(conversation_id, presence_topic, actor)
        end,
        replace: true
      )

    {:ok, socket}
  end

  def update(%{presence: {:leave, presence}}, socket) do
    conversation_id = socket.assigns.conversation_id
    actor = socket.assigns.actor
    presence_topic = socket.assigns.presence_topic

    socket =
      socket
      |> stream_delete(:presences, presence)
      |> stream_async(
        :offline_participants,
        fn ->
          compute_offline_participants(conversation_id, presence_topic, actor)
        end,
        replace: true
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    conversation_id = assigns.conversation_id
    actor = assigns.actor

    socket =
      socket
      |> assign(assigns)
      |> stream(:presences, Presence.list_online_users(assigns.presence_topic))
      |> stream(:offline_participants, [])
      |> stream_async(:offline_participants, fn ->
        compute_offline_participants(conversation_id, assigns.presence_topic, actor)
      end)

    {:ok, socket}
  end

  defp compute_offline_participants(conversation_id, presence_topic, actor) do
    presence_ids = presence_topic |> Presence.list_online_users() |> Enum.map(& &1.id)

    Conversations.participants_not_present!(conversation_id, presence_ids,
      load: [talker: [@talker_preloads]],
      actor: actor
    )
  end

  attr :streams, :map
  attr :offline_participants, Phoenix.LiveView.AsyncResult, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Chat.ConversationSidebar.panel id="participants-panel" title="Participants">
        <Chat.ConversationSidebar.panel_group title="Online">
          <div id="presences_stream" phx-update="stream">
            <Chat.ConversationSidebar.contact
              :for={{dom_id, participant} <- @streams[:presences]}
              id={dom_id}
              image_src={participant.current_profile_pic_source}
              name={participant.full_name}
            >
              <:subtext></:subtext>
            </Chat.ConversationSidebar.contact>
          </div>
        </Chat.ConversationSidebar.panel_group>
        <Chat.ConversationSidebar.panel_group title="Offline">
          <.async_result :let={stream_key} assign={@offline_participants}>
            <:loading>Loading offline participants...</:loading>
            <div id="offline_participants_stream" phx-update="stream">
              <Chat.ConversationSidebar.contact
                :for={{dom_id, participant} <- @streams[stream_key]}
                id={dom_id}
                image_src={participant.talker.current_profile_pic_source}
                name={participant.talker.full_name}
                timestamp={participant.last_active}
                online_status="avatar-offline"
              >
                <:subtext></:subtext>
              </Chat.ConversationSidebar.contact>
            </div>
          </.async_result>
        </Chat.ConversationSidebar.panel_group>
      </Chat.ConversationSidebar.panel>
    </div>
    """
  end
end
