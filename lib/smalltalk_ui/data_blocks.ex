defmodule SmalltalkUi.DataBlocks do
  use Phoenix.Component

  alias Smalltalk.Uploads

  attr :online_status, :string, default: nil, values: ["avatar-online", "avatar-offline", nil]
  attr :size, :string, default: "w-8"
  attr :rounded?, :boolean, default: true
  attr :src, :string, required: true
  attr :image_type, :atom, values: Uploads.ImageTag.values()
  attr :image_format, :atom, values: Uploads.ImageFormat.values(), default: :webp
  attr :alt_text, :string

  def avatar(assigns) do
    ~H"""
    <div class={["avatar", @online_status]}>
      <div class={[@size, if(@rounded?, do: "rounded-full")]}>
        <img
          src={
            Uploads.image_path!(
              @src,
              @image_type,
              %{format: @image_format}
            )
          }
          alt={@alt_text}
        />
      </div>
    </div>
    """
  end

  attr :display_count, :integer, default: 3
  attr :data, :list, required: true
  attr :size, :string, default: "w-8"

  slot :avatar_template, required: true

  def avatar_group(assigns) do
    assigns =
      assigns
      |> assign(
        :remaining_count,
        max(length(assigns.data) - assigns.display_count, 0)
      )

    ~H"""
    <div class="avatar-group -space-x-6">
      <%= for item <- Enum.take(@data, @display_count) do %>
        {render_slot(@avatar_template, item)}
      <% end %>

      <div :if={@remaining_count > 0} class="avatar avatar-placeholder">
        <div class={["bg-neutral text-neutral-content", @size]}>
          <span>+{@remaining_count}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string
  attr :uuid_timestamp, :string, default: nil
  attr :timestamp, DateTime
  attr :format, :atom, default: :default, values: [:default]
  attr :dynamic?, :boolean, default: true

  def timestamp(%{uuid_timestamp: nil, timestamp: nil} = assigns) do
    ~H"""
    """
  end

  def timestamp(assigns) do
    assigns =
      if assigns.uuid_timestamp,
        do: assign(assigns, :timestamp, datetime_from_uuid(assigns.uuid_timestamp)),
        else: assigns

    ~H"""
    <span
      id={@id}
      phx-hook={if(@dynamic?, do: "ResponsiveTimestamp")}
      data-timestamp={DateTime.to_iso8601(@timestamp)}
    >
      {Timex.format!(@timestamp, timestamp_format(@format))}
    </span>
    """
  end

  defp timestamp_format(:time), do: "{h12}:{m}:{s} {AM} (UTC)"
  defp timestamp_format(:wd_short), do: "({WDshort})"
  defp timestamp_format(:date), do: "{D} {Mshort}, {YYYY}"

  defp timestamp_format(:default),
    do: "#{timestamp_format(:date)} #{timestamp_format(:wd_short)}, #{timestamp_format(:time)}"

  defp datetime_from_uuid(uuid) do
    uuid
    |> Ash.UUIDv7.extract_timestamp()
    |> DateTime.from_unix!(:millisecond)
  end
end
