defmodule SmalltalkWeb.Components.Chat.ConversationSidebar do
  use SmalltalkWeb, :html

  def container(assigns) do
    ~H"""
    <div class={[
      "hidden md:block",
      "w-full max-w-80",
      "border-e border-base-300/50",
      "bg-base-200"
    ]}>
      <.tabs>
        <%= for tab <- @tab do %>
          {render_slot(tab)}
        <% end %>
      </.tabs>
      <%= for panel <- @panel do %>
        {render_slot(panel)}
      <% end %>
    </div>
    """
  end

  attr :target, :any, required: true
  attr :event_name, :string, required: true
  attr :active?, :boolean, default: false
  attr :active_classes, :string, default: "text-primary-content border-primary"

  attr :inactive_classes, :string,
    default: "text-base-content/60 border-base-300/50 hover:border-primary/50"

  attr :panel_id, :string, required: true
  attr :panel_container_id, :string, required: true
  attr :icon, :string, required: true

  slot :title, required: true

  def tab(assigns) do
    ~H"""
    <li role="presentation">
      <button
        class={[
          "flex items-center justify-center gap-2",
          "w-full",
          "rounded-t-lg",
          "border-b",
          "px-4 py-5",
          "text-base-content/60",
          if(@active?, do: @active_classes, else: @inactive_classes)
        ]}
        id={"#{@panel_id}-tab"}
        data-tabs-target={"##{@panel_id}"}
        type="button"
        role="tab"
        aria-controls={@panel_id}
        aria-selected="false"
        phx-target={@target}
        phx-click={@event_name}
        phx-value-tab={@panel_id}
      >
        <Icon.icon name={@icon} class="size-6" />
        {render_slot(@title)}
      </button>
    </li>
    """
  end

  def tabs(assigns) do
    ~H"""
    <ul
      data-tabs-active-classes="text-primary-content border-primary"
      data-tabs-inactive-classes="text-base-content/60 border-base-300 hover:border-primary/50"
      class="-mb-px grid grid-cols-2 text-center text-sm font-medium"
      id="contacts-tab"
      data-tabs-toggle="#contacts-tab-content"
      role="tablist"
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr :show?, :boolean, default: true
  attr :id, :string, required: true
  attr :title, :string, required: true

  slot :controls
  slot :inner_block, required: true

  def panel(assigns) do
    ~H"""
    <div
      class={["px-4 py-4", unless(@show?, do: "hidden")]}
      id={@id}
      role="tabpanel"
      aria-labelledby={"#{@id}-tab"}
    >
      <div class="flex items-center justify-between">
        <h2 class="font-medium text-base-content">{@title}</h2>
        {render_slot(@controls)}
      </div>
      <div class="overflow-y-scroll">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :image_src, :string, required: true
  attr :status, :atom, values: [:online, :offline], default: :offline
  attr :name, :string, required: true
  attr :timestamp, :string, required: true
  attr :notification_count, :integer, default: nil

  slot :subtext, doc: "Displays below name (ex. Latest message truncated)" do
    attr :class, :string
  end

  def contact(assigns) do
    ~H"""
    <li class={[
      "px-1 py-2",
      "rounded-lg",
      "flex items-start justify-between",
      "hover:cursor-pointer hover:bg-base-100"
    ]}>
      <div class="flex items-center gap-3">
        <div class="relative shrink-0">
          <img class="h-8 w-8 rounded-full" src={@image_src} alt={"#{@name} image"} />
          <span class={[
            "absolute start-6 top-0
            h-3.5 w-3.5
            rounded-full
            border-2 border-neutral",
            case @status do
              :online -> "bg-success"
              :offline -> "bg-error"
            end
          ]}>
          </span>
        </div>
        <div class="leading-1.5 flex w-full flex-col">
          <span class="text-base font-medium text-base-content">{@name}</span>
          <p
            :if={Enum.any?(@subtext)}
            class={["max-w-52 truncate text-sm font-normal", Map.get(hd(@subtext), :class)]}
          >
            {render_slot(@subtext)}
          </p>
        </div>
      </div>

      <div class="shrink-0">
        <span class="text-xs text-base-content/50">{@timestamp}</span>
      </div>
    </li>
    """
  end

  attr :participants, :list, required: true
  slot :label, required: true

  def participant_group(assigns) do
    ~H"""
    <div>
      <h2 class="text-base-content/70">{render_slot(@label)}</h2>
      <ul>
        <li :for={participant <- @participants}>
          {participant.talker.profile.first_name}
        </li>
      </ul>
    </div>
    """
  end
end
