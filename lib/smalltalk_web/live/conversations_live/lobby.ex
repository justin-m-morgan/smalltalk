defmodule SmalltalkWeb.ConversationsLive.Lobby do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias SmalltalkWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    if connected?(socket) do
      Presence.track_user(actor.id, %{id: actor.id})
      Presence.subscribe()
    end

    socket =
      socket
      |> assign(actor: actor)
      |> stream(
        :presences,
        Presence.list_online_users(),
        replace: true
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({Presence, {:join, presence}}, socket) do
    {:noreply, stream_insert(socket, :presences, presence.user)}
  end

  def handle_info({Presence, {:leave, %{metas: [_ | _]} = presence}}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({Presence, {:leave, presence}}, socket) do
    {:noreply, stream_delete(socket, :presences, presence)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:conversations}
      active_sub_tab={:lobby}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        Lobby
      </Containers.header>

      <ul id="online_users" phx-update="stream" class="grid grid-cols-3 gap-4">
        <li :for={{dom_id, talker} <- @streams[:presences]} id={dom_id}>
          <.user_card talker={talker} my_id={@actor.id} />
        </li>
      </ul>
    </Layouts.app>
    """
  end

  attr :talker, :map, required: true, doc: "Abbreviated details from presence"
  attr :my_id, :string, required: true, doc: "My talker_id"

  defp user_card(assigns) do
    ~H"""
    <Containers.card container_class="bg-base-200 pt-8">
      <:image>
        <div class="avatar">
          <%= if @talker.current_profile_pic_source do %>
            <DataBlocks.avatar
              src={@talker.current_profile_pic_source}
              size="size-64"
              image_type={:medium}
              alt_text={"#{@talker.full_name} Picture"}
            />
          <% else %>
            <Icon.icon name="hero-user" class="size-64" />
          <% end %>
        </div>
      </:image>
      <div class="text-3xl text-center font-bold">
        {@talker.full_name} {if(@my_id == @talker.id, do: "(Me)")}
      </div>
    </Containers.card>
    """
  end
end
