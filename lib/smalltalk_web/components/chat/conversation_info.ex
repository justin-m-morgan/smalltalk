defmodule SmalltalkWeb.Components.Chat.ConversationInfo do
  use SmalltalkWeb, :html

  alias Smalltalk.Uploads

  attr :participants, :list, required: true
  attr :display_count, :integer, default: 4, doc: "Number of Avatars to show"

  slot :main_text, required: true
  slot :controls

  def container(assigns) do
    assigns =
      assigns
      |> assign(
        :remaining_count,
        max(length(assigns.participants) - assigns.display_count, 0)
      )

    ~H"""
    <div class={[
      "flex items-center justify-between",
      "border-b border-base-300/50 px-4 py-2.5"
    ]}>
      <div class="flex items-center gap-3">
        <div class="avatar-group -space-x-6">
          <div
            :for={
              participant <-
                Enum.take(@participants, @display_count)
            }
            class="avatar"
          >
            <div class="w-12">
              <img
                src={
                  Uploads.ImageProcessor.image_path(
                    participant.talker.current_profile_pic.original_src,
                    :thumbnail
                  )
                }
                alt={participant.talker.profile.first_name}
              />
            </div>
          </div>

          <div :if={@remaining_count > 0} class="avatar avatar-placeholder">
            <div class="bg-neutral text-neutral-content w-12">
              <span>+{@remaining_count}</span>
            </div>
          </div>
        </div>
        <div class="leading-1.5 flex w-full flex-col">
          <span class="text-base-content font-medium">
            {render_slot(@main_text)}
          </span>
        </div>
      </div>
      <div class="flex items-center gap-2">
        {render_slot(@controls)}
      </div>
    </div>
    """
  end
end
