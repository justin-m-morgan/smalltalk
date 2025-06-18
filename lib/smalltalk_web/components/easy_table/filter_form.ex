defmodule SmalltalkWeb.Components.EasyTable.FilterForm do
  use SmalltalkWeb, :html

  attr :filter_form, Phoenix.HTML.Form, required: true
  attr :filters, :list, required: true, doc: "Config for filters"
  attr :rest, :global, include: ~w/phx-change phx-target/

  def form(assigns) do
    ~H"""
    <Forms.simple_form form={@filter_form} hide_actions?={true} {@rest}>
      <.inputs_for :let={component} field={@filter_form[:components]}>
        <input type="hidden" name={component[:field].name} value={component[:field].value} />
        <input type="hidden" name={component[:operator].name} value={component[:operator].value} />
        <.filter_form_component component={component} filters={@filters} />
      </.inputs_for>
    </Forms.simple_form>
    """
  end

  def filter_form_component(
        %{component: %{source: %AshPhoenix.FilterForm.Predicate{}}, kind: :checkbox_group} =
          assigns
      ) do
    ~H"""
    <Forms.checkbox_group
      field={@component[:value]}
      legend={Phoenix.Naming.humanize(@component[:field].value)}
      options={@filters[@component[:field].value].options}
    />
    """
  end

  def filter_form_component(
        %{component: %{source: %AshPhoenix.FilterForm.Predicate{}}, kind: :checkbox} =
          assigns
      ) do
    ~H"""
    <Forms.input
      field={@component[:value]}
      type="checkbox"
      label={Phoenix.Naming.humanize(@component[:field].value)}
    />
    """
  end

  def filter_form_component(
        %{component: %{source: %AshPhoenix.FilterForm.Predicate{}}, kind: _kind} =
          assigns
      ) do
    ~H"""
    <p class="text-error">No input configured for {@kind}</p>
    """
  end

  def filter_form_component(
        %{component: %{source: %AshPhoenix.FilterForm.Predicate{}}} =
          assigns
      ) do
    field = assigns.component[:field].value

    assigns =
      assign(assigns, :kind, assigns.filters[field].kind)

    filter_form_component(assigns)
  end

  def filter_form(resource, filters) do
    Enum.reduce(
      filters,
      AshPhoenix.FilterForm.new(resource),
      fn {_key, %{filter: filter} = config}, form ->
        default_value =
          case filter.operation do
            operation when operation in [:in] ->
              (config[:default] || [])
              |> Enum.map(&to_string/1)
              |> Enum.uniq()
              |> dbg()

            _ ->
              config[:default]
          end

        AshPhoenix.FilterForm.add_predicate(
          form,
          filter.field,
          filter.operation,
          default_value,
          path: filter[:path] || []
        )
      end
    )
    |> to_form(as: "filter_form")
  end
end
