defmodule SmalltalkWeb.ConversationsLive.Index do
  use SmalltalkWeb, :live_view

  alias SmalltalkWeb.Components.{Chat, ConversationList}

  @impl true
  def handle_params(params, _session, socket) do
    actor = socket.assigns.talker

    conversation_id = Map.get(params, "conversation_id")

    socket =
      socket
      |> assign(actor: actor, conversation_id: conversation_id)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:conversations}
      active_sub_tab={:mine}
      current_user={@current_user}
      talker={@talker}
    >
      <%= if @conversation_id do %>
        <Containers.header>
          <.link patch={~p"/conversations"}>
            <Icon.icon name="hero-arrow-left" /> Back to Conversations
          </.link>
        </Containers.header>

        <.live_component module={Chat} id="chat" conversation_id={@conversation_id} actor={@actor} />
      <% else %>
        <.live_component
          module={ConversationList}
          id="conversations"
          actor={@actor}
          action={:get_my_conversations!}
          preloads={[:participants]}
        />
      <% end %>
    </Layouts.app>
    """
  end
end
