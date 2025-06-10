defmodule SmalltalkWeb.Components.Chat do
  use SmalltalkWeb, :live_component
  use LiveStreamAsync

  alias Smalltalk.Conversations
  alias Smalltalk.Uploads
  alias SmalltalkWeb.Components.Chat

  @impl true
  def update(assigns, socket) do
    actor = assigns.actor
    conversation_id = assigns.conversation_id

    socket =
      socket
      |> assign(assigns)
      |> assign(form: form(actor, %{}))
      |> assign_new(:active_panel, fn -> "participants" end)
      |> assign_async(:conversation, fn ->
        conversation =
          Conversations.get_conversation!(conversation_id,
            load: [participants: [talker: [:profile, :current_profile_pic]]],
            actor: actor
          )

        {:ok, %{conversation: conversation}}
      end)
      |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
      |> stream_async(
        :messages,
        fn ->
          Conversations.get_messages_for_conversation!(
            %{conversation_id: conversation_id},
            load: [
              talker: [:profile, :current_profile_pic],
              read_receipts: [talker: [:profile, :current_profile_pic]]
            ],
            actor: actor
          )
          |> dbg()
        end,
        reset: true
      )

    {:ok, socket}
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
            Ash.load!(message, [talker: [:profile, :current_profile_pic]],
              actor: socket.assigns.actor
            )

          socket
          |> stream_insert(:messages, message)

        {:error, form} ->
          assign(socket, form: form)
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.async_result :let={_conversation} assign={@conversation}>
        <:loading>
          <Containers.card container_class="bg-primary text-primary-content animate-pulse">
            <:title>
              Loading Conversation
            </:title>
          </Containers.card>
        </:loading>
        <:failed>
          <Containers.card container_class="bg-error text-error-content">
            <:title>
              Failed to Load Conversation
            </:title>
          </Containers.card>
        </:failed>

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
              target={@myself}
              event_name="activate-tab"
              icon="hero-user-group-solid"
            >
              <:title>Participants</:title>
            </Chat.ConversationSidebar.tab>

            <Chat.ConversationSidebar.tab
              panel_id="admin"
              panel_container_id="sidebar_panels"
              active?={@active_panel == "admin"}
              target={@myself}
              event_name="activate-tab"
              icon="hero-cog-6-tooth-solid"
            >
              <:title>Admin Options</:title>
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
              <.async_result :let={%{participants: participants}} assign={@conversation}>
                <:loading>Loading Participants</:loading>
                <:failed>Failed to Load Conversation</:failed>
                <Chat.ConversationSidebar.contact
                  :for={participant <- participants}
                  image_src={
                    Uploads.ImageProcessor.image_path(
                      participant.talker.current_profile_pic.original_src,
                      :thumbnail
                    )
                  }
                  name={participant.talker.profile.first_name}
                  timestamp="2 days ago"
                >
                  <:subtext></:subtext>
                </Chat.ConversationSidebar.contact>
              </.async_result>
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
                      <Chat.Messages.avatar
                        src={message.talker.current_profile_pic.original_src}
                        alt_text={"#{message.talker.profile.first_name} image"}
                      />
                    </:left_gutter>
                    <:right_gutter>
                      <Chat.Messages.avatar
                        src={message.talker.current_profile_pic.original_src}
                        alt_text={"#{message.talker.profile.first_name} image"}
                      />
                    </:right_gutter>
                    <Chat.Messages.contact_info
                      name={message.talker.profile.first_name}
                      timestamp={format_time(message.id)}
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
            phx-target={@myself}
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
      </.async_result>
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

  defp format_time(uuid) when is_binary(uuid) do
    uuid
    |> Ash.UUIDv7.extract_timestamp()
    |> DateTime.from_unix!(:millisecond)
    |> format_time()
  end

  defp format_time(%DateTime{} = timestamp) do
    time_portion = "{h12}:{m}:{s} {AM} (UTC)"
    date_portion = "{D} {Mshort}, {YYYY} ({WDshort})"

    format =
      if Timex.compare(timestamp, DateTime.utc_now(), :day) < 0,
        do: time_portion <> ", " <> date_portion,
        else: time_portion

    Timex.format!(timestamp, format)
  end
end
