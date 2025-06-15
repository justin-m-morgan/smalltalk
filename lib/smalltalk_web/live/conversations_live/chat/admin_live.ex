defmodule SmalltalkWeb.ConversationsLive.Chat.Admin do
  use SmalltalkWeb, :live_view

  @impl true
  def mount(%{"conversation_id" => conversation_id}, _session, socket) do
    socket =
      socket
      |> assign(conversation_id: conversation_id)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:conversations}
      active_sub_tab={nil}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        <.link navigate={~p"/conversations/#{@conversation_id}"}>
          <div class="flex items-center gap-4">
            <Icon.icon name="hero-arrow-left" class="size-6" />
            <span>Back to Conversation</span>
          </div>
        </.link>
      </Containers.header>

      <div class="grid grid-cols-2 gap-4">
        <Containers.card container_class="bg-base-200">
          <:title>Admins</:title>
        </Containers.card>
        <Containers.card container_class="bg-base-200">
          <:title>Participants</:title>
        </Containers.card>
        <Containers.card container_class="bg-base-200">
          <:title>Stats</:title>
        </Containers.card>
      </div>
    </Layouts.app>
    """
  end
end
