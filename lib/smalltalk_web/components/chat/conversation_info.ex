defmodule SmalltalkWeb.Components.Chat.ConversationInfo do
  use SmalltalkWeb, :html

  attr :img_src, :string
  attr :img_alt_text, :string

  slot :main_text, required: true
  slot :controls

  def container(assigns) do
    ~H"""
    <div class={[
      "flex items-center justify-between",
      "border-b border-base-300/50 px-4 py-2.5"
    ]}>
      <div class="flex items-center gap-3">
        <div class="relative shrink-0">
          <img class="h-8 w-8 rounded-full" src={@img_src} alt={@img_alt_text} />
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
