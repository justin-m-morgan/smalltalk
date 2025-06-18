defmodule SmalltalkUi.Table do
  use Phoenix.Component
  use Gettext, backend: SmalltalkWeb.Gettext

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """

  attr :id, :string, required: true
  attr :fixed_width_columns?, :boolean, default: true
  attr :th_classes, :string, default: nil, doc: "Useful for setting column widths"
  attr :rows, :list, required: true
  attr :row_classes, :string, default: nil
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :caption

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  slot :empty_results

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class={["table", if(@fixed_width_columns?, do: "table-fixed")]}>
      <caption class="text-xl font-bold">{render_slot(@caption)}</caption>
      <thead>
        <tr>
          <th :for={col <- @col} class={@th_classes}>{col[:label]}</th>
          <th :if={@action != []} class={@th_classes}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr
          :for={row <- @rows}
          id={@row_id && @row_id.(row)}
          class={[@row_click && "hover:bg-accent"]}
        >
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex justify-end gap-2">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>

        <tr class="hidden only:table-row">
          <td colspan={length(@col) + 1}>
            <.empty_results>
              <%= if Enum.any?(@empty_results) do %>
                {render_slot(@empty_results)}
              <% else %>
                No Results Found
              <% end %>
            </.empty_results>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  slot :inner_block

  def empty_results(assigns) do
    ~H"""
    <div class="py-16 text-center text-5xl font-bold border border-base-300 bg-base-200 rounded-lg">
      {render_slot(@inner_block)}
    </div>
    """
  end
end
