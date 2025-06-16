defmodule SmalltalkWeb.ConversationsLive.Chat.MessageListLive do
  use SmalltalkWeb, :live_component
  use LiveStreamAsync

  alias Smalltalk.Uploads
  alias Smalltalk.Conversations
  alias Phoenix.LiveView.JS

  @talker_preloads [:full_name, :current_profile_pic_source]

  @impl true

  def update(%{new_message: message}, socket) do
    actor = socket.assigns.actor
    message = Ash.load!(message, [talker: @talker_preloads], actor: actor)

    socket =
      stream_insert(socket, :messages, message)

    {:ok, socket}
  end

  def update(%{update_pagination: {offset, more?}}, socket) do
    pagination =
      socket.assigns.pagination
      |> Map.put(:more?, more?)
      |> Map.put(:offset, offset)

    socket = assign(socket, pagination: pagination)

    {:ok, socket}
  end

  def update(assigns, socket) do
    pid = self()
    component_id = assigns.id
    actor = assigns.actor
    conversation_id = assigns.conversation_id
    initial_message_load_count = assigns[:initial_message_load_count] || 5

    socket =
      socket
      |> assign(assigns)
      |> assign(
        pagination: %{
          offset: initial_message_load_count,
          limit: initial_message_load_count,
          more?: false
        }
      )
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

          update_pagination(pid, component_id, offset, more?)

          Enum.reverse(results)
        end
      )

    {:ok, socket}
  end

  defp update_pagination(pid, id, offset, more?),
    do: send_update(pid, __MODULE__, id: id, update_pagination: {offset, more?})

  @impl true
  def handle_event("load_more_messages", _unsigned_params, socket) do
    self_id = socket.assigns.id
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

    update_pagination(self(), self_id, offset, more?)

    socket =
      Enum.reduce(results, socket, fn result, socket ->
        stream_insert(socket, :messages, result, at: 0)
      end)

    {:noreply, socket}
  end

  attr :actor, Conversations.Talker, required: true
  attr :messages, Phoenix.LiveView.AsyncResult, required: true
  attr :pagination, :map, required: true
  attr :streams, :map, required: true

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-between">
      <div class="overflow-scroll h-full">
        <.container id="messages-stream-container" phx-hook="ChatWindow" data-event-name="chat-window">
          <:top_overlay_controls>
            <Button.button
              :if={@pagination.more?}
              color="btn-accent"
              type="button"
              class="absolute left-1/2 top-0"
              phx-target={@myself}
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

            <.message_container
              :for={{id, message} <- @streams[stream_key]}
              id={id}
              mine?={@actor.id == message.talker_id}
            >
              <:left_gutter>
                <DataBlocks.avatar
                  size="size-10"
                  image_type={:thumbnail}
                  src={message.talker.current_profile_pic_source}
                  alt_text={"#{message.talker.full_name} image"}
                />
              </:left_gutter>
              <:right_gutter>
                <DataBlocks.avatar
                  size="size-10"
                  image_type={:thumbnail}
                  src={message.talker.current_profile_pic_source}
                  alt_text={"#{message.talker.full_name} image"}
                />
              </:right_gutter>
              <.contact_info
                name={message.talker.full_name}
                uuid_timestamp={message.id}
                formatted_timestamp={format_time(message.id)}
              />
              <.message_bubble mine?={@actor.id == message.talker_id}>
                {message.content}
              </.message_bubble>
            </.message_container>
          </.async_result>
        </.container>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rest, :global, include: ~w/phx-update data-event-name/

  slot :top_overlay_controls
  slot :bottom_overlay_controls
  slot :inner_block, required: true

  def container(assigns) do
    assigns = assign(assigns, event_name: Map.get(assigns.rest, :"data-event-name"))

    ~H"""
    <div class="relative h-full overflow-hidden">
      <div>
        <div
          :for={slot <- [@top_overlay_controls, @bottom_overlay_controls]}
          class={[
            "absolute",
            "flex justify-center w-full",
            "opacity-10 hover:opacity-100 transition-opacity",
            "first:mt-2 last:mb-2 last:bottom-0",
            "overflow-hidden"
          ]}
        >
          {render_slot(slot)}
        </div>
      </div>

      <div
        id={@id}
        phx-update="stream"
        class={[
          "h-full",
          "grid grid-cols-[3rem_1fr_3rem] auto-rows-min gap-2",
          "overflow-y-scroll",
          "px-4 py-12"
        ]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :mine?, :boolean, required: true
  slot :left_gutter, doc: "Display content for others messages"
  slot :right_gutter, doc: "Display content for my messages"
  slot :inner_block, required: true

  def message_container(assigns) do
    ~H"""
    <div id={@id} data-container-type="message" class="grid col-span-full grid-cols-subgrid">
      <div class={["mx-auto", if(@mine?, do: "invisible")]}>
        {render_slot(@left_gutter)}
      </div>
      <div class={["flex flex-col gap-1", if(@mine?, do: "items-end", else: "items-start")]}>
        {render_slot(@inner_block)}
      </div>
      <div class={["mx-auto", unless(@mine?, do: "invisible")]}>
        {render_slot(@right_gutter)}
      </div>
    </div>
    """
  end

  attr :src, :string, required: true
  attr :alt_text, :string, required: true
  attr :size, :string, default: "size-8"

  def avatar(assigns) do
    ~H"""
    <div class="avatar">
      <div class={["rounded-full", @size]}>
        <img
          src={
            Uploads.image_path(
              @src,
              :thumbnail
            )
          }
          alt={@alt_text}
        />
      </div>
    </div>
    """
  end

  attr :mine?, :boolean, default: false
  attr :name, :string, required: true
  attr :uuid_timestamp, :string, required: true
  attr :formatted_timestamp, :string, required: true

  def contact_info(assigns) do
    ~H"""
    <div class={["flex items-center space-x-2 rtl:space-x-reverse", if(@mine?, do: "justify-end")]}>
      <a
        href="#"
        class={[
          "text-sm font-semibold",
          "text-base-content",
          "hover:cursor-pointer hover:underline"
        ]}
      >
        {@name}
      </a>
      <DataBlocks.timestamp
        id={"#{@uuid_timestamp}-message-timestamp"}
        uuid_timestamp={@uuid_timestamp}
      />
    </div>
    """
  end

  attr :mine?, :boolean, default: false
  attr :contact_name, :string, required: true
  attr :contact_image_src, :string, required: true
  attr :timestamp, :string, required: true
  slot :top, required: true
  slot :middle, required: true
  slot :bottom, required: true

  def group(assigns) do
    ~H"""
    <div class={[
      "group flex max-w-3/4 items-start gap-2",
      if(@mine?, do: "ml-auto flex-row-reverse")
    ]}>
      <img class="h-8 w-8 rounded-full" src={@contact_image_src} alt={"#{@contact_name} image"} />
      <div class="flex flex-col gap-1">
        <div class={["flex items-center space-x-2 rtl:space-x-reverse", if(@mine?, do: "justify-end")]}>
          <a
            href="#"
            class={[
              "text-sm font-semibold",
              "text-base-content",
              "hover:cursor-pointer hover:underline"
            ]}
          >
            {@contact_name}
          </a>
          <span class="text-sm font-normal text-base-content/70">{@timestamp}</span>
        </div>
        <div class={[
          "flex flex-col gap-2",
          if(@mine?, do: "items-end")
        ]}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :mine?, :boolean, default: false
  slot :inner_block, required: true

  def message_bubble(assigns) do
    ~H"""
    <div class="space-y-1 text-start">
      <div class={[
        "inline-flex flex-col",
        "rounded-xl",
        if(@mine?, do: "rounded-tr-none", else: "rounded-tl-none"),
        "border-gray-200",
        "bg-base-100",
        "p-4"
      ]}>
        <p class="text-sm font-normal text-gray-900 dark:text-white">{render_slot(@inner_block)}</p>
      </div>
    </div>
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
