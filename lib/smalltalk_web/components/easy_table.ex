defmodule SmalltalkWeb.Components.EasyTable do
  use SmalltalkWeb, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias SmalltalkWeb.Components.EasyTable

  @impl true
  def update(%{event: %{name: _} = _event}, socket) do
    # Some optimizations could be made to surgically update stream on update/delete
    socket =
      socket
      |> start_async_read()

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(
        filter_form: EasyTable.FilterForm.filter_form(assigns.resource, assigns[:filters] || []),
        page: AsyncResult.loading(),
        current_sort_key: nil,
        current_sort_direction: nil,
        sorts:
          assigns.col
          |> Enum.reduce([], fn col, acc ->
            if sort_key = Map.get(col, :sort_key),
              do: [{sort_key, Map.get(col, :sort_directions, [:asc, :desc])} | acc],
              else: acc
          end)
      )
      |> assign_new(:display_mode, fn -> "table" end)
      |> then(&assign(&1, :base_query, base_query(&1)))
      |> start_async_read()

    {:ok, socket}
  end

  def start_async_read(socket, opts \\ []) do
    base_query = socket.assigns.base_query
    opts = Keyword.merge(socket.assigns.opts, opts)
    {sort, opts} = Keyword.pop(opts, :sort, socket.assigns.default_sort || {:id, :asc})
    filter_form = socket.assigns[:filter_form]

    searchable_fields = socket.assigns[:searchable_fields]

    search_pattern =
      socket.assigns[:search_pattern] || fn search_query -> [ilike: "%#{search_query}%"] end

    search = opts[:search]

    query =
      base_query
      |> Ash.Query.sort(sort)
      |> maybe_apply_search_filter(search, searchable_fields, search_pattern)
      |> maybe_apply_filter_form(filter_form)

    start_async(socket, :read, fn ->
      Ash.read!(query)
    end)
  end

  @impl true
  def handle_async(:read, {:ok, page}, socket) do
    socket =
      socket
      |> assign_page_and_stream_results(page)

    {:noreply, socket}
  end

  @impl true
  def handle_event("table-navigate", params, socket) do
    direction = params["direction"] && String.to_existing_atom(params["direction"])
    page_number = params["page_number"] && String.to_integer(params["page_number"])

    page = Ash.page!(socket.assigns.page.result, direction || page_number)

    socket =
      socket
      |> assign_page_and_stream_results(page)

    {:noreply, socket}
  end

  def handle_event("sort", %{"sort_key" => sort_key}, socket) do
    sort_key = String.to_existing_atom(sort_key)
    supported_sorts = socket.assigns.sorts[sort_key]

    next_sort =
      if socket.assigns.current_sort_key == sort_key,
        do:
          supported_sorts
          |> Stream.cycle()
          |> Stream.drop_while(&(&1 != socket.assigns.current_sort_direction))
          |> Stream.drop(1)
          |> Enum.take(1)
          |> hd(),
        else: hd(supported_sorts)

    socket =
      socket
      |> assign(current_sort_key: sort_key, current_sort_direction: next_sort)
      |> start_async_read(sort: {sort_key, next_sort})

    {:noreply, socket}
  end

  def handle_event("search-table", %{"search_query" => search_query}, socket) do
    socket =
      socket
      |> assign(search_query: search_query)
      |> start_async_read(search: search_query)

    {:noreply, socket}
  end

  def handle_event("apply-filters", params, socket) do
    form = socket.assigns.filter_form.source
    params = Map.get(params, socket.assigns.filter_form.name)

    filter_form =
      AshPhoenix.FilterForm.validate(form, params) |> to_form(as: "filter_form")

    socket =
      socket
      |> assign(filter_form: filter_form)
      |> start_async_read()

    {:noreply, socket}
  end

  def handle_event("toggle-display-mode", _, socket) do
    display_mode =
      ["table", "cards"]
      |> Stream.cycle()
      |> Stream.drop_while(&(&1 == socket.assigns.display_mode))
      |> Enum.take(1)
      |> List.first()

    socket =
      socket
      |> assign(:display_mode, display_mode)
      |> start_async_read()

    {:noreply, socket}
  end

  attr :id, :string, required: true
  attr :fixed_width_columns?, :boolean, default: true
  attr :border, :string, default: "border-none"
  attr :striped?, :boolean, default: false
  attr :bg, :string, default: nil
  attr :table_class, :string, default: nil

  attr :size, :string,
    default: nil,
    values: [nil, "table-xs", "table-sm", "table-md", "table-lg", "table-xl"]

  attr :th_classes, :string, default: nil, doc: "Useful for setting column widths"

  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  attr :searchable_fields, :list, default: nil

  attr :filters, :list, default: [], doc: "Config provided to setup filters"
  attr :filter_form, Phoenix.HTML.Form, required: true

  slot :caption

  slot :col, required: true do
    attr :label, :string
    attr :sort_key, :atom
    attr :sort_directions, :list
  end

  slot :action, doc: "the slot for showing user actions in the last table column"
  slot :empty_results
  slot :card_template

  def render(assigns) do
    ~H"""
    <div>
      <.controls
        id={@id}
        myself={@myself}
        filter_form={@filter_form}
        filters={@filters}
        searchable_fields={@searchable_fields}
        display_mode={@display_mode}
        toggle_display_mode_event="toggle-display-mode"
        search_event="search-table"
        filter_event="apply-filters"
      />

      <.async_result :let={page} assign={@page}>
        <.cards
          :if={@display_mode == "cards"}
          caption={@caption}
          streams={@streams}
          row_item={@row_item}
          card_template={@card_template}
          col={@col}
          action={@action}
          empty_results={@empty_results}
        />
        <.table
          :if={@display_mode == "table"}
          id={@id}
          border={@border}
          bg={@bg}
          size={@size}
          table_class={@table_class}
          fixed_width_columns?={@fixed_width_columns?}
          striped?={@striped?}
          caption={@caption}
          col={@col}
          th_classes={@th_classes}
          myself={@myself}
          current_sort_key={@current_sort_key}
          current_sort_direction={@current_sort_direction}
          action={@action}
          streams={@streams}
          page={page}
          row_click={@row_click}
          row_item={@row_item}
          empty_results={@empty_results}
        />
      </.async_result>
    </div>
    """
  end

  def cards(assigns) do
    ~H"""
    <h2 class="text-2xl font-bold text-center pb-4">{render_slot(@caption)}</h2>
    <div phx-stream="stream" class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      <div class="hidden only:block col-span-full">
        <.empty_results>
          <%= if Enum.any?(@empty_results) do %>
            {render_slot(@empty_results)}
          <% else %>
            No Results Found
          <% end %>
        </.empty_results>
      </div>
      <Containers.card :for={{dom_id, row} <- @streams.rows} id={dom_id} container_class="bg-base-200">
        <%= if Enum.any?(@card_template) do %>
          {render_slot(@card_template, @row_item.(row))}
        <% else %>
          <Containers.list>
            <:item :for={col <- @col} title={col[:label]}>
              {render_slot(col, @row_item.(row))}
            </:item>
            <:item title="Actions">
              <div class="grid gap-2">
                <%= for action <- @action do %>
                  {render_slot(action, {dom_id, row})}
                <% end %>
              </div>
            </:item>
          </Containers.list>
        <% end %>
      </Containers.card>
    </div>
    """
  end

  def table(assigns) do
    ~H"""
    <table class={[
      "table table-pin-rows",
      @border,
      @bg,
      @size,
      @table_class,
      if(@striped?, do: "table-zebra"),
      if(@fixed_width_columns?, do: "table-fixed")
    ]}>
      <caption class="text-2xl font-bold">{render_slot(@caption)}</caption>

      <thead>
        <tr>
          <th :for={col <- @col} class={@th_classes}>
            <button
              type="button"
              phx-click={if Map.get(col, :sort_key), do: "sort"}
              phx-target={@myself}
              phx-value-sort_key={Map.get(col, :sort_key)}
              class={[
                "cursor-pointer hover:text-accent",
                if(@current_sort_key == Map.get(col, :sort_key, false), do: "text-accent")
              ]}
            >
              <Icon.icon
                :if={sort_key = Map.get(col, :sort_key)}
                name={
                  case {@current_sort_key, @current_sort_direction} do
                    {^sort_key, direction} when direction in [:asc, :asc_nils_first] ->
                      "hero-bars-arrow-up"

                    {^sort_key, direction} when direction in [:desc, :desc_nils_last] ->
                      "hero-bars-arrow-down"

                    _ ->
                      "hero-arrows-up-down"
                  end
                }
                class="size-6"
              />
              <span>{col[:label]}</span>
            </button>
          </th>
          <th :if={@action != []} class={@th_classes}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>

      <tbody id={@id} phx-update="stream">
        <tr
          :for={{dom_id, row} <- @streams.rows}
          id={dom_id}
          class={[@row_click && "hover:bg-accent"]}
        >
          <.cell :for={col <- @col} row={row}>
            {render_slot(col, @row_item.(row))}
          </.cell>
          <td class="flex justify-end gap-2">
            <%= for action <- @action do %>
              {render_slot(action, {dom_id, row})}
            <% end %>
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
      <tfoot>
        <tr>
          <td colspan={length(@col) + max(1, length(@action))}>
            <.pagination page={@page} myself={@myself} />
          </td>
        </tr>
      </tfoot>
    </table>
    """
  end

  attr :id, :string, required: true
  attr :display_mode, :string, required: true, values: ["table", "cards"]
  attr :myself, :any, required: true
  attr :filter_form, Phoenix.HTML.Form, required: true
  attr :filters, :list, required: true
  attr :searchable_fields, :list, required: true
  attr :toggle_display_mode_event, :string, required: true
  attr :search_event, :string, required: true
  attr :filter_event, :string, required: true

  def controls(assigns) do
    ~H"""
    <div class="flex justify-between py-8">
      <div>
        <form :if={@searchable_fields} phx-change={@search_event} phx-target={@myself} class="w-lg">
          <label class="floating-label">
            <span>Search...</span>
            <input
              type="text"
              class="input input-lg w-full"
              name="search_query"
              placeholder="Search..."
            />
          </label>
        </form>
      </div>

      <div>
        <Button.button
          :if={Enum.any?(@filters)}
          class="btn"
          popovertarget={"#{@id}-filter-dropdown"}
          style={"anchor-name:--#{@id}-anchor"}
        >
          <Icon.icon name="hero-adjustments-horizontal" class="size-8" />
          <span>Filters</span>
        </Button.button>

        <label
          class="toggle toggle-xl h-full w-18 text-base-content"
          phx-click={@toggle_display_mode_event}
          phx-target={@myself}
        >
          <input type="checkbox" checked={@display_mode == "cards"} />
          <Icon.icon name="hero-list-bullet" class="size-8" />
          <Icon.icon name="hero-square-2-stack" class="size-8" />
        </label>
      </div>

      <div
        popover
        id={"#{@id}-filter-dropdown"}
        style={"position-anchor:--#{@id}-anchor; top: anchor(top); bottom: anchor(bottom); left: calc(anchor(right) + 10px)"}
        class={[
          "dropdown menu",
          "w-52",
          "p-4",
          "absolute m-0",
          "rounded-box",
          "bg-base-300 shadow-sm"
        ]}
      >
        <EasyTable.FilterForm.form
          filter_form={@filter_form}
          filters={@filters}
          phx-change={@filter_event}
          phx-target={@myself}
        />
      </div>
    </div>
    """
  end

  attr :page, :map, required: true
  attr :myself, :any, required: true

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(:current_page, floor(assigns.page.offset / assigns.page.limit))
      |> assign(:page_count, ceil(assigns.page.count / assigns.page.limit))

    ~H"""
    <div class="flex justify-between">
      <Button.button
        type="button"
        phx-click="table-navigate"
        phx-value-direction="prev"
        phx-target={@myself}
        disabled={@page.offset == 0}
      >
        Previous Page
      </Button.button>

      <div class="flex flex-col items-center gap-4">
        <div class="join">
          <button
            :for={page_number <- 1..@page_count}
            :if={@page_count > 1}
            phx-click="table-navigate"
            phx-value-page_number={page_number}
            phx-target={@myself}
            class="join-item btn"
          >
            {page_number}
          </button>
        </div>
        <p>
          Showing {@page.offset + 1} - {min(@page.count, @page.offset + @page.limit)} of {@page.count}
        </p>
      </div>
      <Button.button
        type="button"
        phx-click="table-navigate"
        phx-value-direction="next"
        phx-target={@myself}
        disabled={!@page.more?}
      >
        Next Page
      </Button.button>
    </div>
    """
  end

  attr :row, :map, required: true
  attr :row_click, :any, default: nil
  slot :inner_block, required: true

  def cell(assigns) do
    ~H"""
    <td phx-click={@row_click && @row_click.(@row)} class={@row_click && "hover:cursor-pointer"}>
      {render_slot(@inner_block)}
    </td>
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

  def assign_page_and_stream_results(socket, page) do
    socket
    |> stream(:rows, page.results, reset: true)
    |> assign(page: AsyncResult.ok(%{page | results: []}))
  end

  defp maybe_apply_search_filter(query, nil, _searchable_fields, _search_pattern), do: query
  defp maybe_apply_search_filter(query, _search_query, nil, _search_pattern), do: query

  defp maybe_apply_search_filter(query, search_query, searchable_fields, search_pattern)
       when is_list(searchable_fields) do
    search_query =
      searchable_fields
      |> Enum.map(fn field_path ->
        make_path_search_filter(
          field_path,
          search_pattern,
          search_query
        )
      end)

    Ash.Query.filter_input(query, or: search_query)
  end

  defp maybe_apply_filter_form(query, nil), do: query

  defp maybe_apply_filter_form(query, %{source: filter_form}) do
    AshPhoenix.FilterForm.filter!(query, filter_form)
  end

  defp make_path_search_filter(path, pattern, query) do
    path = List.wrap(path) |> Enum.reverse()
    filter = pattern.(query)

    Enum.reduce(path, filter, fn path_segment, acc ->
      [{path_segment, acc}]
    end)
  end

  defp base_query(socket) do
    resource = socket.assigns.resource
    read_action = socket.assigns.read_action
    limit = socket.assigns[:limit] || 5
    args = socket.assigns[:args] || %{}
    opts = socket.assigns[:opts] || []

    resource
    |> Ash.Query.for_read(read_action, args, opts)
    |> Ash.Query.page(count: true, limit: limit, offset: 0)
    |> Ash.Query.filter_input(Keyword.get(opts, :filter, []))
  end
end
