defmodule SmalltalkWeb.TestLive do
  use SmalltalkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="body" phx-hook="ThreeDLogo" class="size-64"></div>
    """
  end
end
