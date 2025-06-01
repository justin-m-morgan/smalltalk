defmodule SmalltalkUi.Modal do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  slot(:inner_block, required: true)

  @doc """
   Renders a modal dialog with an inner block.

   Triggered by calling the "<modal_id>.showModal()" function on a button.
  """
  attr(:id, :string, required: true)
  attr(:open?, :boolean, default: false)
  attr(:on_close, :list, default: [])

  def container(assigns) do
    ~H"""
    <dialog id={@id} class={["modal", if(@open?, do: "modal-open")]}>
      <div class="modal-box">
        <form method="dialog">
          <button
            phx-click={close_modal(@id, @on_close)}
            class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
          >
            ✕
          </button>
        </form>
        {render_slot(@inner_block)}
      </div>
      <div class="modal-backdrop" phx-click={close_modal(@id, @on_close)}></div>
    </dialog>
    """
  end

  def show_modal(id) do
    JS.add_class("modal-open", to: "##{id}")
  end

  def close_modal(id, on_close) do
    JS.remove_class("modal-open", to: "##{id}")
    |> then(
      &Enum.reduce(on_close, &1, fn close_event, js ->
        close_event.(js)
      end)
    )
  end
end
