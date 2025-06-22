defmodule SmalltalkWeb.RoomChannel do
  use SmalltalkWeb, :channel
  alias SmalltalkWeb.Presence

  @impl true
  def join("conversation:lobby", _payload, socket) do
    {:ok, socket}
  end

  def join("conversation:" <> topic, _payload, socket) do
    IO.inspect("============================================")
    IO.inspect(topic, label: "*******************TOPIC******************")
    IO.inspect("============================================")
    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.name, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (conversation:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
