defmodule SmalltalkWeb.ConversationsLive.Chat.ConversationInfo do
  use SmalltalkWeb, :live_component
  use LiveStreamAsync

  alias Smalltalk.Conversations

  @talker_preloads [:full_name, :current_profile_pic_source]

  def update(assigns, socket) do
    conversation_id = assigns.conversation_id
    actor = assigns.actor

    socket =
      socket
      |> assign(assigns)
      |> assign_async(:conversation, fn ->
        {:ok,
         %{
           conversation:
             Conversations.get_conversation!(conversation_id,
               load: [participants: [talker: @talker_preloads]],
               actor: actor
             )
         }}
      end)

    {:ok, socket}
  end

  slot :controls

  def render(assigns) do
    ~H"""
    <div class={[
      "flex items-center justify-between",
      "border-b border-base-300/50 px-4 py-2.5"
    ]}>
      <.async_result :let={conversation} assign={@conversation}>
        <:loading>Loading Conversation</:loading>
        <:failed>Failed to Load Conversation</:failed>
        <div class="flex items-center gap-3">
          <div class="shrink-0">
            <.participants_list participants={conversation.participants} />
          </div>

          <div class="leading-1.5 flex w-full flex-col">
            <span class="text-base-content font-medium">
              {conversation.short_name}
            </span>
          </div>
        </div>
        <div class="flex items-center gap-2">
          {render_slot(@controls)}
        </div>
      </.async_result>
    </div>
    """
  end

  attr :participants, :list, required: true

  defp participants_list(assigns) do
    ~H"""
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
    """
  end
end
