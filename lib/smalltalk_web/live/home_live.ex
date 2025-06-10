defmodule SmalltalkWeb.HomeLive do
  use SmalltalkWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:home}
      active_sub_tab={@live_action}
      current_user={@current_user}
      talker={@talker}
    >
      <div class="grid gap-16">
        Live Action: {@live_action}
      </div>
    </Layouts.app>
    """
  end
end
