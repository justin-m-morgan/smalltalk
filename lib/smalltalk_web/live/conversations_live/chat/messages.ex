defmodule SmalltalkWeb.ConversationsLive.Chat.Messages do
  use SmalltalkWeb, :html

  alias Smalltalk.Uploads

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
          "grid grid-cols-[3rem_1fr_3rem] gap-2",
          "overflow-y-scroll"
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
end
