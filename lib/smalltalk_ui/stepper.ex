defmodule SmalltalkUi.Stepper do
  use Phoenix.Component

  attr(:direction, :string,
    values: ["steps-vertical", "steps-horizontal"],
    default: "steps-vertical"
  )

  attr(:current_step, :string)
  attr(:patch_page, :string)
  slot(:inner_block, required: true)

  slot :step, required: true do
    attr(:key, :string, required: true)
  end

  slot(:step_content, required: true)

  def container(assigns) do
    keys = Enum.map(assigns.step, & &1.key) |> Enum.reverse()
    {after_current, to_current} = Enum.split_while(keys, &(&1 != assigns.current_step))

    assigns = assign(assigns, to_current: to_current, after_current: after_current)

    ~H"""
    <div class="grid grid-cols-4 items-start">
      <ul class={["steps", @direction]}>
        <%= for step <- @step do %>
          <.step
            patch={@patch_page <> "?current_step=#{step.key}"}
            color={if step.key in @to_current, do: "step-primary"}
          >
            {render_slot(step)}
          </.step>
        <% end %>
      </ul>
      <div class="py-4 px-8 col-span-3">
        <h2 class="text-xl font-bold">
          {render_slot(Enum.find(@step, &(&1.key == @current_step)))}
        </h2>
        {render_slot(@step_content)}
      </div>
    </div>
    """
  end

  attr(:color, :string,
    values: [
      nil,
      "step-neutral",
      "step-primary",
      "step-secondary",
      "step-accent",
      "step-info",
      "step-success",
      "step-warning",
      "step-error"
    ],
    default: nil
  )

  attr(:data_content, :string, default: nil, doc: "Inserts inside circle, overriding number")
  attr(:patch, :string)
  slot(:icon)
  slot(:inner_block, required: true)

  def step(assigns) do
    ~H"""
    <li class={["step", @color]} data-content={@data_content}>
      <span :if={Enum.any?(@icon)} class="step-icon">{render_slot(@icon)}</span>
      <.link patch={@patch}>{render_slot(@inner_block)}</.link>
    </li>
    """
  end
end
