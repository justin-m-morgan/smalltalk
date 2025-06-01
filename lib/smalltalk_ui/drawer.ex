defmodule SmalltalkUi.Drawer do
  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:placement, :atom, default: :left, values: [:left, :right])
  attr(:open?, :boolean, default: false)
  slot(:inner_block, required: true)
  slot(:drawer_content, required: true)

  def container(assigns) do
    ~H"""
    <div class={[
      "drawer",
      if(@placement == :right, do: "drawer-end"),
      if(@open?, do: "md:drawer-open")
    ]}>
      <input id={@id} type="checkbox" class="drawer-toggle" />
      <div class="drawer-content">
        {render_slot(@inner_block)}
      </div>
      <div class="drawer-side">
        <label for={@id} aria-label="close sidebar" class="drawer-overlay"></label>
        <div class="bg-base-200 text-base-content min-h-full w-80 p-4">
          {render_slot(@drawer_content)}
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :string, default: "btn btn-primary ")
  slot(:inner_block, required: true)

  def trigger(assigns) do
    ~H"""
    <label for={@id} class={["drawer-button", @class]}>
      {render_slot(@inner_block)}
    </label>
    """
  end
end
