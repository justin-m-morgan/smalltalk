defmodule SmalltalkWeb.ConversationsLive.Chat do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations
  alias SmalltalkWeb.ConversationsLive.Chat
  alias SmalltalkWeb.Presence

  @talker_preloads [:full_name, :current_profile_pic_source, :profile]

  @impl true
  def handle_params(%{"conversation_id" => conversation_id}, _uri, socket) do
    actor = socket.assigns.talker
    self = self()

    new_messages_pubsub_topic =
      Conversations.subscribe_to_new_messages!(conversation_id, actor: actor)

    presence_topic = "conversation:#{conversation_id}"

    socket =
      socket
      |> assign(
        conversation_id: conversation_id,
        actor: actor,
        new_messages_topic: new_messages_pubsub_topic,
        presence_topic: presence_topic
      )
      |> assign(form: form(actor, %{}))
      |> assign_new(:active_panel, fn -> "participants" end)
      |> assign_async(:conversation, fn ->
        conversation =
          Conversations.get_conversation!(conversation_id,
            load: [participants: [talker: @talker_preloads]],
            actor: actor
          )

        Process.send_after(self, :update_last_active, 5_000)
        {:ok, %{conversation: conversation}}
      end)
      |> stream_async(
        :messages,
        fn ->
          Conversations.get_messages_for_conversation!(
            %{conversation_id: conversation_id},
            load: [
              talker: @talker_preloads,
              read_receipts: [talker: @talker_preloads]
            ],
            actor: actor
          )

          # JS.dispatch(@event_name, to: "##{@target}", detail: %{"direction" => @direction})
        end
      )
      |> stream(:presences, Presence.list_online_users(presence_topic))
      |> stream(:offline_participants, [])
      |> stream_async(:offline_participants, fn ->
        compute_offline_participants(conversation_id, presence_topic, actor)
      end)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Smalltalk.PubSub, new_messages_pubsub_topic)
      Presence.track_user(actor.id, %{id: actor.id}, presence_topic)
      Presence.subscribe(presence_topic)
    end

    {:noreply, socket}
  end

  defp compute_offline_participants(conversation_id, presence_topic, actor) do
    presence_ids = presence_topic |> Presence.list_online_users() |> Enum.map(& &1.id)

    Conversations.participants_not_present!(conversation_id, presence_ids,
      load: [talker: [@talker_preloads]],
      actor: actor
    )
  end

  @impl true
  def handle_event("activate-tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :active_panel, tab)
    {:noreply, socket}
  end

  def handle_event("send_message", params, socket) do
    params = Map.get(params, socket.assigns.form.name)
    original_form = socket.assigns.form

    socket =
      case AshPhoenix.Form.submit(original_form, params: params) do
        {:ok, message} ->
          message =
            Ash.load!(message, [talker: @talker_preloads], actor: socket.assigns.actor)

          socket
          |> stream_insert(:messages, message)

        {:error, form} ->
          assign(socket, form: form)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:update_last_active, socket) do
    actor = socket.assigns.actor

    socket.assigns.conversation.result.participants
    |> Enum.find(&(&1.talker_id == actor.id))
    |> Conversations.update_last_active!(actor: actor)

    Process.send_after(self(), :update_last_active, 60_000)

    {:noreply, socket}
  end

  def handle_info(
        %{topic: topic, event: "create", payload: %{data: message}},
        socket
      )
      when topic == socket.assigns.new_messages_topic do
    message = Ash.load!(message, [talker: @talker_preloads], actor: socket.assigns.actor)

    socket =
      stream_insert(socket, :messages, message)

    {:noreply, socket}
  end

  def handle_info({Presence, {:join, presence}}, socket) do
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

    {:noreply, socket}
  end

  def handle_info({Presence, {:leave, presence}}, socket) do
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

        <.async_result :let={conversation} assign={@conversation}>
          <:loading>Loading Conversation</:loading>
          <:failed>Failed to Load Conversation</:failed>
          <Chat.ConversationInfo.container participants={conversation.participants}>
            <:main_text>{conversation.short_name}</:main_text>
          </Chat.ConversationInfo.container>
        </.async_result>

        <div
          id="sidebar_panels"
          class={[
            "overflow-scroll",
            "border-r border-base-300/50",
            "row-span-2"
          ]}
        >
          <Chat.ConversationSidebar.panel
            id="participants"
            title="Participants"
            show?={@active_panel == "participants"}
          >
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
          <Chat.ConversationSidebar.panel
            id="admin"
            title="Admin Options"
            show?={@active_panel == "admin"}
          >
            <.async_result :let={%{participants: participants}} assign={@conversation}>
              <:loading>Loading Conversation</:loading>
              <:failed>Failed to Load Conversation</:failed>
              <div class="grid gap-4 py-4">
                <Chat.ConversationSidebar.participant_group participants={participants}>
                  <:label>Suspended</:label>
                </Chat.ConversationSidebar.participant_group>
              </div>
            </.async_result>
          </Chat.ConversationSidebar.panel>
        </div>

        <div class="flex flex-col justify-between relative">
          <div class="overflow-scroll">
            <Chat.Messages.container
              id="messages-stream-container"
              phx-hook="ChatWindow"
              data-event-name="chat-window"
              phx-update="stream"
            >
              <.async_result :let={stream_key} assign={@messages}>
                <:failed>Failed to Load Conversation</:failed>

                <div
                  id="messages-empty"
                  class={[
                    "hidden",
                    "only-of-type:flex justify-center items-center",
                    "p-4 bg-base-300/40 col-span-full h-32 m-12 rounded-lg "
                  ]}
                >
                  <p class="text-3xl font-bold">No messages yet.</p>
                </div>

                <Chat.Messages.message_container
                  :for={{id, message} <- @streams[stream_key]}
                  id={id}
                  mine?={@actor.id == message.talker_id}
                >
                  <:left_gutter>
                    <DataBlocks.avatar
                      size="size-10"
                      image_type={:thumbnail}
                      src={message.talker.current_profile_pic_source}
                      alt_text={"#{message.talker.profile.first_name} image"}
                    />
                  </:left_gutter>
                  <:right_gutter>
                    <DataBlocks.avatar
                      size="size-10"
                      image_type={:thumbnail}
                      src={message.talker.current_profile_pic_source}
                      alt_text={"#{message.talker.profile.first_name} image"}
                    />
                  </:right_gutter>
                  <Chat.Messages.contact_info
                    name={message.talker.profile.first_name}
                    uuid_timestamp={message.id}
                    formatted_timestamp={format_time(message.id)}
                  />
                  <Chat.Messages.message_bubble mine?={@actor.id == message.talker_id}>
                    {message.content}
                  </Chat.Messages.message_bubble>
                </Chat.Messages.message_container>
              </.async_result>
            </Chat.Messages.container>
          </div>
        </div>
        <Forms.simple_form
          form={@form}
          class="flex justify-between items-start gap-2"
          actions_container_classes="h-full"
          phx-submit="send_message"
        >
          <input type="hidden" name={@form[:conversation_id].name} value={@conversation_id} />
          <Forms.textarea_input
            phx-debounce="1000"
            type="textarea"
            rows={5}
            field={@form[:content]}
            input_class="w-full"
          />

          <:submit_button size="h-full btn-xl">
            <Icon.icon name="hero-paper-airplane-solid" class="size-12" />
          </:submit_button>
        </Forms.simple_form>
      </div>
    </Layouts.app>
    """
  end

  defp form(actor, params) do
    [params: params, actor: actor, as: "send_message"]
    |> Conversations.form_to_send_message()
    |> to_form()
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

  defp format_time(nil), do: ""

  defp format_time(uuid) when is_binary(uuid) do
    uuid
    |> Ash.UUIDv7.extract_timestamp()
    |> DateTime.from_unix!(:millisecond)
    |> format_time()
  end

  defp format_time(%DateTime{} = timestamp) do
    time_portion = "{h12}:{m}:{s} {AM} (UTC)"
    date_portion = "{D} {Mshort}, {YYYY} ({WDshort})"

    format = time_portion <> ", " <> date_portion

    Timex.format!(timestamp, format)
  end
end
