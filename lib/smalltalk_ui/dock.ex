defmodule SmalltalkUi.Dock do
  use Phoenix.Component
  alias SmalltalkUi.Icon

  def container(assigns) do
    ~H"""
    <div class="dock dock-xl">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:active?, :boolean, default: false)
  attr(:icon, :string, required: true)
  attr(:navigate, :string, default: "#")
  slot(:inner_block, required: true)

  def item(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "after:border-accent after:bg-accent",
        if(@active?, do: "dock-active")
      ]}
    >
      <span class={if(@active?, do: "animate-bounce")}>
        <Icon.icon name={@icon} class="size-8" />
      </span>
      <span class="dock-label">
        {render_slot(@inner_block)}
      </span>
    </.link>
    """
  end
end
