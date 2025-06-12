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
end
