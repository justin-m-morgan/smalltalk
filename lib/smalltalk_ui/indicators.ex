defmodule SmalltalkUi.Indicators do
  use Phoenix.Component

  attr :style, :string,
    default: nil,
    values: ["badge-outline", "badge-dash", "badge-soft", "badge-ghost", nil]

  attr :color, :string,
    default: "badge-primary",
    values: [
      "badge-neutral",
      "badge-primary",
      "badge-secondary",
      "badge-success",
      "badge-error",
      "badge-warning",
      "badge-info",
      "badge-accent"
    ]

  attr :size, :string,
    default: "badge-md",
    values: ["badge-xs", "badge-sm", "badge-md", "badge-lg", "badge-xl", nil]

  attr :class, :string, default: nil, doc: "Additional Classes"

  slot :inner_block

  def badge(assigns) do
    ~H"""
    <div class={["badge", @style, @color, @size, @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
