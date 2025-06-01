defmodule SmalltalkUi.Menu do
  use Phoenix.Component

  attr(:class, :string, default: "bg-base-200 text-base-content")

  attr(:size, :string,
    default: "menu-md",
    values: [
      "menu-xs",
      "menu-sm",
      "menu-md",
      "menu-lg",
      "menu-xl"
    ]
  )

  attr(:orientation, :string, default: "menu-vertical")
  slot(:inner_block, required: true)

  def container(assigns) do
    ~H"""
    <ul class={["menu", @orientation, @class]}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr(:to, :string, default: "#")
  attr(:disabled?, :boolean, default: false)
  attr(:active?, :boolean, default: false)
  attr(:focused?, :boolean, default: false)
  attr(:class, :string, default: "bg-base-200 text-base-content")

  slot(:inner_block, required: true)
  slot(:sub_menu)

  def linked_item(assigns) do
    ~H"""
    <li class={[
      if(@disabled?, do: "menu-disabled cursor-not-allowed"),
      if(@focused?, do: "menu-focused")
    ]}>
      <.link navigate={unless(@disabled?, do: @to)} class={if(@active?, do: "menu-active")}>
        {render_slot(@inner_block)}
      </.link>
      {render_slot(@sub_menu)}
    </li>
    """
  end
end
