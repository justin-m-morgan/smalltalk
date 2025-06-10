defmodule SmalltalkLayouts.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use SmalltalkWeb, :html

  embed_templates("layouts/*")

  attr(:site_section, :string, default: "Home")
  attr(:current_user, Smalltalk.Accounts.User, default: nil)

  slot(:link)

  def header(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <.link navigate={~p"/"} class="flex-1 flex items-center gap-2">
          <.branding secondary_text={@site_section} />
        </.link>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li :for={link <- @link}>
            {render_slot(link)}
          </li>
          <li>
            <.user_control current_user={@current_user} />
          </li>
          <li>
            <Theme.theme_toggle />
          </li>
        </ul>
      </div>
    </header>
    """
  end

  attr(:text_size, :string, default: "text-6xl")
  attr(:secondary_text, :string, default: nil)
  slot(:logo)

  def branding(assigns) do
    ~H"""
    <div class="flex items-center">
      {render_slot(@logo)}
      <div class={[@text_size, "font-bold"]}>
        <span>Smalltalk</span>
        <span class="text-secondary">{@secondary_text}</span>
      </div>
    </div>
    """
  end

  def logo(assigns) do
    ~H"""
    """
  end

  def user_control(assigns) do
    ~H"""
    <div class="absolute inset-y-0 right-0 flex items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0">
      <%= if @current_user do %>
        <span class="px-3 py-2 text-sm font-medium text-white rounded-md">
          {@current_user.email}
        </span>
        <a
          href="/sign-out"
          class="rounded-lg bg-zinc-100 px-2 py-1 text-[0.8125rem] font-semibold leading-6 text-zinc-900 hover:bg-zinc-200/80 active:text-zinc-900/70"
        >
          Sign out
        </a>
      <% else %>
        <a
          href="/sign-in"
          class="rounded-lg bg-zinc-100 px-2 py-1 text-[0.8125rem] font-semibold leading-6 text-zinc-900 hover:bg-zinc-200/80 active:text-zinc-900/70"
        >
          Sign In
        </a>
      <% end %>
    </div>
    """
  end

  attr :active_tab, :atom, default: nil
  attr :active_sub_tab, :atom, default: nil
  attr :flash, :map, default: %{}
  attr :current_user, :map, default: nil
  attr :talker, :map, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    assigns =
      assigns
      |> assign(
        :menu,
        [
          home: %{
            to: ~p"/"
          },
          account: %{
            to: ~p"/account",
            sub_menu: [
              contact: %{
                to: ~p"/account/contact"
              },
              subscription: %{
                to: ~p"/account/subscription"
              }
            ]
          },
          profile: %{
            to: ~p"/profile"
          },
          friends: %{
            to: ~p"/friends",
            sub_menu: [
              current: %{
                to: ~p"/friends"
              },
              search: %{
                to: ~p"/friends/search"
              },
              requests: %{
                to: ~p"/friends/requests"
              }
            ]
          },
          conversations: %{
            to: ~p"/conversations/",
            sub_menu: [
              mine: %{
                to: ~p"/conversations/"
              },
              search: %{
                to: ~p"/conversations/search"
              }
            ]
          }
        ]
        |> Enum.reject(fn {key, _} ->
          is_nil(assigns.talker.profile) and key not in [:home, :profile]
        end)
      )

    ~H"""
    <Drawer.container id="main-drawer" open?={true}>
      <:drawer_content>
        <.branding text_size="text-3xl" />

        <Menu.container>
          <%= for {key, menu} <- @menu do %>
            <Menu.linked_item active?={@active_tab == key} to={menu[:to]}>
              {menu[:label] || Phoenix.Naming.humanize(key)}

              <:sub_menu>
                <Menu.container :if={menu[:sub_menu]}>
                  <Menu.linked_item
                    :for={{sub_key, sub_menu} <- menu.sub_menu}
                    active?={@active_tab == key && @active_sub_tab == sub_key}
                    to={sub_menu.to}
                  >
                    {menu[:label] || Phoenix.Naming.humanize(sub_key)}
                  </Menu.linked_item>
                </Menu.container>
              </:sub_menu>
            </Menu.linked_item>
          <% end %>
        </Menu.container>
      </:drawer_content>
      <.header current_user={@current_user} site_section={Phoenix.Naming.humanize(@active_tab)} />

      <main class="px-4 py-20 sm:px-6 lg:px-8">
        <div class="mx-auto container">
          {render_slot(@inner_block)}
        </div>
      </main>
      <%!-- <Dock.container>
        <Dock.item active?={@active_tab == :home} navigate={~p[/]} icon="hero-home">
          Home
        </Dock.item>
      </Dock.container> --%>
    </Drawer.container>
    <Flash.flash_group flash={@flash} />
    """
  end
end
