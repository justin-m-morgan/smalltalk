defmodule SmalltalkWeb.ConversationsLive.Chat.ConversationInfo do
  use SmalltalkWeb, :html

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
        <DataBlocks.avatar_group data={@participants}>
          <:avatar_template :let={participant}>
            <DataBlocks.avatar
              size="size-8"
              src={participant.talker.current_profile_pic_source}
              image_type={:thumbnail}
              alt_text={"#{participant.talker.full_name}"}
            />
          </:avatar_template>
        </DataBlocks.avatar_group>

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
