defmodule SmalltalkWeb.ConversationsLive.Search do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias SmalltalkWeb.Components.ConversationList

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    socket =
      socket
      |> assign(actor: actor)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:conversations}
      active_sub_tab={:search}
      current_user={@current_user}
      talker={@talker}
    >
      <.live_component
        module={ConversationList}
        id="conversations"
        actor={@actor}
        action={:get_conversations!}
        preloads={[:participants]}
      />
    </Layouts.app>
    """
  end
end
