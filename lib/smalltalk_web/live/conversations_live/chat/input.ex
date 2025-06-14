defmodule SmalltalkWeb.ConversationsLive.Chat.Input do
  use SmalltalkWeb, :html

  def text_area(assigns) do
    ~H"""
    <form>
      <label for="chat" class="sr-only">Your message</label>
      <div class="flex items-center px-3 py-2">
        <textarea id="chat" rows="6" class="textarea w-full" placeholder="Your message..."></textarea>

        <%!-- <.control_button>
          <:icon>
            <Icon.icon name="hero-photo" class="size-9" />
          </:icon>
          Upload Image
        </.control_button>
        <.control_button>
          <:icon>
            <Icon.icon name="hero-face-smile" class="size-9" />
          </:icon>
          Add Emoji
        </.control_button> --%>
        <.control_button>
          <:icon>
            <Icon.icon name="hero-paper-airplane" class="size-9" />
          </:icon>
          Send Message
        </.control_button>
      </div>
    </form>
    """
  end

  attr :class, :string, default: nil
  slot :icon, required: true
  slot :inner_block, required: true

  defp control_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "inline-flex justify-center",
        "p-2",
        "text-base-content/80 hover:text-base-content",
        "hover:bg-base-100 rounded-lg",
        "cursor-pointer"
      ]}
    >
      {render_slot(@icon)}
      <span class="sr-only">{render_slot(@inner_block)}</span>
    </button>
    """
  end
end
