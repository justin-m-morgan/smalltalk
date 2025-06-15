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

    new_messages_topic =
      Conversations.subscribe_to_new_messages!(conversation_id, actor: actor)

    presence_topic = "conversation:#{conversation_id}"

    initial_message_load_count = 5

    self = self()

    socket =
      socket
      |> assign(
        pagination: %{
          offset: initial_message_load_count,
          limit: initial_message_load_count,
          more?: false
        },
        conversation_id: conversation_id,
        actor: actor,
        new_messages_topic: new_messages_topic,
        presence_topic: presence_topic,
        unblock_event: "unblock_participant"
      )
      |> assign(form: form(actor, %{content: ""}))
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
          %{results: results, more?: more?, offset: offset} =
            Conversations.get_messages_for_conversation!(
              %{conversation_id: conversation_id},
              page: [limit: initial_message_load_count, offset: 0],
              load: [
                talker: @talker_preloads,
                read_receipts: [talker: @talker_preloads]
              ],
              actor: actor
            )

          send(self, {:update_pagination, offset, more?})

          Enum.reverse(results)
        end
      )
      |> stream(:presences, Presence.list_online_users(presence_topic))
      |> stream(:offline_participants, [])
      |> stream_async(:offline_participants, fn ->
        compute_offline_participants(conversation_id, presence_topic, actor)
      end)
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

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Smalltalk.PubSub, new_messages_topic)
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
    topic = socket.assigns.new_messages_topic

    socket =
      case AshPhoenix.Form.submit(original_form, params: params) do
        {:ok, message} ->
          send(self(), %{topic: topic, event: "create", payload: %{data: message}})

          socket
          |> assign(:form, form(actor, %{content: ""}))

        {:error, form} ->
          assign(socket, form: form)
      end

    {:noreply, socket}
  end

  def handle_event("load_more_messages", _unsigned_params, socket) do
    pagination = socket.assigns.pagination
    actor = socket.assigns.actor
    conversation_id = socket.assigns.conversation_id

    page =
      pagination
      |> Map.update!(:offset, fn offset -> pagination.limit + offset end)
      |> Map.drop([:more?])

    %{results: results, more?: more?, offset: offset} =
      Conversations.get_messages_for_conversation!(
        %{conversation_id: conversation_id},
        page: page,
        load: [
          talker: @talker_preloads,
          read_receipts: [talker: @talker_preloads]
        ],
        actor: actor
      )

    send(self(), {:update_pagination, offset, more?})

    socket =
      Enum.reduce(results, socket, fn result, socket ->
        stream_insert(socket, :messages, result, at: 0)
      end)

    {:noreply, socket}
  end

  def handle_event("unblock_participant", %{"participant_id" => participant_id}, socket) do
    actor = socket.assigns.actor
    conversation_id = socket.assigns.conversation_id

    Conversations.get_participant!(participant_id, actor: actor)
    |> Conversations.unblock_participant!(actor: actor)

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

  def handle_info({:update_pagination, offset, more?}, socket) do
    pagination =
      socket.assigns.pagination
      |> Map.put(:more?, more?)
      |> Map.put(:offset, offset)

    socket = assign(socket, pagination: pagination)

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
          <.panel_participants
            active_panel={@active_panel}
            streams={@streams}
            offline_participants={@offline_participants}
          />
          <.panel_admin
            active_panel={@active_panel}
            admins={@admins}
            blocked={@blocked}
            unblock_event={@unblock_event}
            streams={@streams}
          />
        </div>

        <.messages_list
          actor={@actor}
          messages_stream_assign={@messages}
          pagination={@pagination}
          streams={@streams}
        />

        <.message_form form={@form} conversation_id={@conversation_id} />
      </div>
    </Layouts.app>
    """
  end

  attr :active_panel, :atom, required: true
  attr :streams, :map
  attr :offline_participants, Phoenix.LiveView.AsyncResult, required: true

  defp panel_participants(assigns) do
    ~H"""
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
    """
  end

  attr :active_panel, :atom, required: true
  attr :admins, Phoenix.LiveView.AsyncResult, required: true
  attr :blocked, Phoenix.LiveView.AsyncResult, required: true
  attr :unblock_event, :string, required: true
  attr :streams, :map, required: true

  def panel_admin(assigns) do
    ~H"""
    <Chat.ConversationSidebar.panel id="admin" title="Admin Options" show?={@active_panel == "admin"}>
      <.async_result :let={stream_key} assign={@admins}>
        <:loading>Loading Admins</:loading>
        <:failed>Failed to Load Admins</:failed>
        <div class="grid gap-4 py-4">
          <Chat.ConversationSidebar.participant_group
            id="admin-stream"
            participants={@streams[stream_key]}
          >
            <:label>Admins</:label>
          </Chat.ConversationSidebar.participant_group>
        </div>
      </.async_result>
      <.async_result :let={stream_key} assign={@blocked}>
        <:loading>Loading Blocked Participants</:loading>
        <:failed>Failed to Load Blocked Participants</:failed>
        <div class="grid gap-4 py-4">
          <Chat.ConversationSidebar.participant_group
            id="admin-stream"
            participants={@streams[stream_key]}
          >
            <:label>Blocked</:label>
            <:actions :let={participant}>
              <Button.button
                phx-click={@unblock_event}
                phx-value-participant_id={participant.id}
                size="btn-xs"
              >
                Unblock
              </Button.button>
            </:actions>
          </Chat.ConversationSidebar.participant_group>
        </div>
      </.async_result>
    </Chat.ConversationSidebar.panel>
    """
  end

  attr :actor, Conversations.Talker, required: true
  attr :messages_stream_assign, Phoenix.LiveView.AsyncResult, required: true
  attr :pagination, :map, required: true
  attr :streams, :map, required: true

  defp messages_list(assigns) do
    ~H"""
    <div class="flex flex-col justify-between">
      <div class="overflow-scroll h-full">
        <Chat.Messages.container
          id="messages-stream-container"
          phx-hook="ChatWindow"
          data-event-name="chat-window"
        >
          <:top_overlay_controls>
            <Button.button
              :if={@pagination.more?}
              color="btn-accent"
              type="button"
              class="absolute left-1/2 top-0"
              phx-click="load_more_messages"
            >
              <Icon.icon name="hero-plus" class="size-6" /> Load More
            </Button.button>
          </:top_overlay_controls>
          <:bottom_overlay_controls>
            <Button.button
              color="btn-accent"
              size="btn-xl"
              size_modifier="btn-circle"
              phx-click={
                JS.dispatch("chat-window",
                  to: "#messages-stream-container",
                  detail: %{"direction" => "bottom"}
                )
              }
            >
              <Icon.icon name="hero-arrow-down" class="size-6" />
            </Button.button>
          </:bottom_overlay_controls>
          <.async_result :let={stream_key} assign={@messages_stream_assign}>
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
    """
  end

  attr :conversation_id, :string, required: true
  attr :form, Phoenix.HTML.Form, required: true

  defp message_form(assigns) do
    ~H"""
    <div class="p-4 flex">
      <Forms.simple_form
        id="new-message-form"
        form={@form}
        class="flex justify-between gap-2 grow-1"
        actions_container_classes="h-full "
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
