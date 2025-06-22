defmodule SmalltalkWeb.Hooks.AddLogoHook do
  use Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    IO.inspect("===========CALLING HOOK==========")

    {:cont,
     push_event(socket, "js-set-logo-hook", %{
       to: ".three-d-logo:first-of-type",
       attr: "phx-hook",
       value: "ThreeDLogo"
     })}
  end
end
