defmodule SmalltalkUi.Containers do
  use Phoenix.Component
  alias SmalltalkUi.Icon

  @doc """
  A card
  """
  attr(:container_class, :any, default: nil)
  attr(:id, :string, default: nil)

  slot(:image)
  slot(:title)
  slot(:inner_block, required: true)
  slot(:actions)

  def card(assigns) do
    ~H"""
    <div id={@id} class={["card shadow-sm", @container_class]}>
      <figure>
        {render_slot(@image)}
      </figure>
      <div class="card-body">
        <h2 class="card-title">
          {render_slot(@title)}
        </h2>
        {render_slot(@inner_block)}
        <div class="card-actions justify-end mt-auto">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:actions)

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  attr(:container_class, :string, default: "min-h-screen")
  slot(:main_caption, required: true)
  slot(:secondary_text, required: true)
  slot(:image)
  slot(:cta)

  def hero(assigns) do
    ~H"""
    <div class={["hero", @container_class]}>
      <div class="hero-content text-center">
        <div class="max-w-md">
          <div>
            {render_slot(@image)}
          </div>
          <h1 class="text-5xl font-bold">{render_slot(@main_caption)}</h1>

          {render_slot(@secondary_text)}

          {render_slot(@cta)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)
  slot(:title)

  def section(assigns) do
    ~H"""
    <section class={@class}>
      <h2 :if={Enum.any?(@title)} class="text-3xl font-bold pb-4">{render_slot(@title)}</h2>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr(:stat_figure, :string, default: nil, doc: "Icon to appear alongside stat")
  attr(:label, :map, required: true)
  attr(:stat, :map, required: true)
  attr(:detail, :map, default: nil)
  slot(:actions)

  def stat(assigns) do
    ~H"""
    <div class="stats shadow">
      <div class="stat">
        <div :if={@stat_figure} class="stat-figure">
          <Icon.icon name={@stat_figure} class="size-8" />
        </div>
        <div class="stat-title"><.stat_line {@label} /></div>
        <div class="stat-value"><.stat_line {@stat} /></div>
        <div :if={@detail} class="stat-desc"><.stat_line {@detail} /></div>
        <div :if={@actions} class="stat-actions">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end

  attr(:text, :string, required: true)
  attr(:icon, :string, default: nil)
  attr(:icon_placement, :atom, values: [:before, :after], default: :before)
  attr(:accent, :string, default: nil)

  def stat_line(assigns) do
    ~H"""
    <div class={@accent}>
      <Icon.icon :if={@icon} name={@icon} />
      <span>{@text}</span>
    </div>
    """
  end
end
