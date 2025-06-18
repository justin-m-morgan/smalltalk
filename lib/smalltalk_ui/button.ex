defmodule SmalltalkUi.Button do
  use Phoenix.Component

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr(:rest, :global, include: ~w(href navigate patch method onclick disabled popovertarget))

  attr(:color, :string,
    default: "btn-primary",
    values:
      ~w(btn-primary btn-neutral btn-secondary btn-accent btn-info btn-success btn-warning btn-error)
  )

  attr(:size_modifier, :string, values: ~w(btn-wide btn-block btn-square btn-circle))
  attr(:variant, :string, values: ~w(btn-outline btn-dash btn-soft btn-ghost btn-link))
  attr(:status, :string, values: ~w(btn-active btn-disabled))
  attr(:size, :string, values: ~w(btn-xs btn-sm btn-md btn-lg btn-xl))

  slot(:inner_block, required: true)

  def button(%{rest: rest} = assigns) do
    classes =
      assigns
      |> Map.take([:color, :size_modifier, :variant, :status, :size])
      |> Map.values()

    assigns = assign(assigns, :class, classes)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={["btn", @class]} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={["btn", @class]} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end
end
