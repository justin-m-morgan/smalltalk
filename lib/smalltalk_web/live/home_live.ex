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
      <div class="hero bg-base-200 rounded-lg">
        <div class="hero-content text-center flex flex-col items-center">
          <Layouts.logo size="size-64 md:w-96 md:h-64" />
          <h1 class="text-3xl md:text-7xl font-bold">
            Welcome to Smalltalk
          </h1>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
