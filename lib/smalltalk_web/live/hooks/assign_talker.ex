defmodule SmalltalkWeb.Hooks.AssignTalker do
  @moduledoc """
  Maybe create and assign `Talker` for the current user.
  """
  use SmalltalkWeb, :verified_routes

  import Phoenix.Component

  alias Smalltalk.Conversations

  def on_mount(:default, _params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      case Conversations.get_me(load: [:profile], actor: current_user) do
        {:ok, talker} ->
          assign(socket, :talker, talker)

        {:error, _} ->
          assign(
            socket,
            :talker,
            Conversations.create_talker!(load: [:profile], actor: current_user)
          )
      end

    {:cont, socket}
  end
end
