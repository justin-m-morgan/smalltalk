defmodule SmalltalkWeb.ConversationsLive.Chat do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations
  alias SmalltalkWeb.ConversationsLive.Chat
  alias SmalltalkWeb.Presence

  @impl true
  def mount(%{"conversation_id" => conversation_id}, _session, socket) do
    socket =
      case Conversations.get_participant_by_actor_conversation(
             conversation_id,
             socket.assigns.talker.id,
             load: [:is_approved?],
             actor: socket.assigns.talker
           ) do
        {:ok, %{is_approved?: true}} ->
          socket

        _ ->
          socket
          |> put_flash(
            :error,
            "Your conversation is still pending approval. Please wait until it's approved before continuing."
          )
          |> redirect(to: ~p[/conversations/])
      end

    {:ok, socket}
  end

  @impl true
  @spec handle_params(map(), any(), any()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_params(%{"conversation_id" => conversation_id}, _uri, socket) do
    actor = socket.assigns.talker

    new_messages_topic =
      Conversations.subscribe_to_new_messages!(conversation_id, actor: actor)

    presence_topic = "conversation:#{conversation_id}"

    Process.send_after(self(), :update_last_active, 5_000)

    socket =
      socket
      |> assign(
        conversation_id: conversation_id,
        actor: actor,
        new_messages_topic: new_messages_topic,
        presence_topic: presence_topic,
        unblock_event: "unblock_participant"
      )
      |> assign_new(:active_panel, fn -> "participants" end)
      |> assign_async(:participant, fn ->
        {:ok,
         %{
           participant:
             Conversations.get_participant_by_actor_conversation!(conversation_id, actor.id,
               actor: actor
             )
         }}
      end)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Smalltalk.PubSub, new_messages_topic)
      Presence.track_user(actor.id, %{id: actor.id}, presence_topic)
      Presence.subscribe(presence_topic)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("activate-tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :active_panel, tab)
    {:noreply, socket}
  end

  #
  @impl true
  def handle_info(:update_last_active, socket) do
    actor = socket.assigns.actor

    socket.assigns.participant.result
    |> Conversations.update_last_active!(actor: actor)

    Process.send_after(self(), :update_last_active, 60_000)

    {:noreply, socket}
  end

  def handle_info(
        %{topic: topic, event: "create", payload: %{data: message}},
        socket
      )
      when topic == socket.assigns.new_messages_topic do
    send_update(Chat.MessageListLive,
      id: "conversation-message-list",
      new_message: message
    )

    {:noreply, socket}
  end

  def handle_info({Presence, {:join, presence}}, socket) do
    send_update(Chat.ParticipantsPanelLive,
      id: "conversation-participants-panel",
      presence: {:join, presence}
    )

    {:noreply, socket}
  end

  def handle_info({Presence, {:leave, presence}}, socket) do
    send_update(Chat.ParticipantsPanelLive,
      id: "conversation-participants-panel",
      presence: {:leave, presence}
    )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:conversations}
      active_sub_tab={nil}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        <.link navigate={~p"/conversations"}>
          <div class="flex items-center gap-4">
            <Icon.icon name="hero-arrow-left" class="size-6" />
            <span>Back to Your Conversations</span>
          </div>
        </.link>
      </Containers.header>

      <div class={[
        "grid grid-cols-[1fr_2fr]",
        "grid-rows-[max-content_60vh_max-content]",
        "bg-base-200",
        "p-2",
        "rounded-lg"
      ]}>
        <Chat.ConversationSidebar.tabs>
          <Chat.ConversationSidebar.tab
            panel_id="participants"
            panel_container_id="sidebar_panels"
            active?={@active_panel == "participants"}
            event_name="activate-tab"
            icon="hero-user-group-solid"
          >
            <:title>Participants</:title>
          </Chat.ConversationSidebar.tab>

          <Chat.ConversationSidebar.tab
            panel_id="admin"
            panel_container_id="sidebar_panels"
            active?={@active_panel == "admin"}
            event_name="activate-tab"
            icon="hero-cog-6-tooth-solid"
          >
            <:title>Admin</:title>
          </Chat.ConversationSidebar.tab>
        </Chat.ConversationSidebar.tabs>

        <.live_component
          id="conversation-info-banner"
          module={Chat.ConversationInfo}
          conversation_id={@conversation_id}
          actor={@actor}
        />

        <div
          id="sidebar_panels"
          class={[
            "overflow-scroll",
            "border-r border-base-300/50",
            "row-span-2"
          ]}
        >
          <.live_component
            :if={@active_panel == "participants"}
            id="conversation-participants-panel"
            module={Chat.ParticipantsPanelLive}
            actor={@actor}
            conversation_id={@conversation_id}
            presence_topic={@presence_topic}
          />
          <.live_component
            :if={@active_panel == "admin"}
            id="conversation-admin-panel"
            module={Chat.AdminPanelLive}
            actor={@actor}
            conversation_id={@conversation_id}
          />
        </div>
        <.live_component
          id="conversation-message-list"
          module={Chat.MessageListLive}
          actor={@actor}
          conversation_id={@conversation_id}
        />
        <.live_component
          id="conversation-message-input"
          module={Chat.InputLive}
          actor={@actor}
          conversation_id={@conversation_id}
        />
      </div>
    </Layouts.app>
    """
  end

  attr :target_panel_id, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  def sidebar_tab(assigns) do
    ~H"""
    <li role="presentation">
      <button
        class="flex w-full items-center justify-center rounded-t-lg border-b px-4 py-5 text-gray-500 dark:text-gray-400"
        id={"#{@target_panel_id}-tab"}
        data-tabs-target={@target_panel_id}
        type="button"
        role="tab"
        aria-controls={@target_panel_id}
        aria-selected="false"
      >
        <Icon.icon name={@icon} />
        {render_slot(@inner_block)}
      </button>
    </li>
    """
  end
end
