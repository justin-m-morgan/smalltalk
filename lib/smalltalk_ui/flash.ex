defmodule SmalltalkUi.Flash do
  use Phoenix.Component
  use Gettext, backend: SmalltalkWeb.Gettext
  alias Phoenix.LiveView.JS
  alias SmalltalkUi.Icon
  alias SmalltalkUi.JsCommands

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:success, :info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JsCommands.hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :success && "alert-success",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <Icon.icon :if={@kind == :success} name="hero-check-badge" class="size-5 shrink-0" />
        <Icon.icon :if={@kind == :info} name="hero-information-circle-mini" class="size-5 shrink-0" />
        <Icon.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <Icon.icon name="hero-x-mark-solid" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <Flash.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash kind={:success} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          JsCommands.show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")
        }
        phx-connected={JsCommands.hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <Icon.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          JsCommands.show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")
        }
        phx-connected={JsCommands.hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <Icon.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
