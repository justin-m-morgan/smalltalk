defmodule SmalltalkWeb.Hooks.ForceProfileCreate do
  @moduledoc """
  Redirect to profile page if no profile yet
  """
  use SmalltalkWeb, :verified_routes

  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    talker = Ash.load!(socket.assigns.talker, [:profile], authorize?: false)

    if !talker.profile && socket.view != SmalltalkWeb.ProfileLive.Edit,
      do:
        {:halt,
         socket
         |> Phoenix.LiveView.put_flash(:error, "Please create a profile first")
         |> redirect(to: "/profile/edit")},
      else: {:cont, socket}
  end
end
