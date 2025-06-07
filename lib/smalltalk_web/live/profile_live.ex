defmodule SmalltalkWeb.ProfileLive do
  use SmalltalkWeb, :live_view

  alias Smalltalk.Conversations
  alias SmalltalkWeb.Components.Profile

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker
    socket = assign(socket, actor: actor, profile: socket.assigns.talker.profile)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:profile_saved, profile}, socket) do
    socket =
      socket
      |> assign(profile: profile, live_action: nil)
      |> push_patch(to: ~p"/profile")
      |> put_flash(:success, "Profile saved successfully!")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:profile}
      active_sub_tab={@live_action}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        Profile
        <:actions>
          <Button.button :if={@live_action != :edit} size="btn-lg" patch={~p"/profile/edit"}>
            {if @profile, do: "Update Profile", else: "Create a profile"}
          </Button.button>
        </:actions>
      </Containers.header>

      <%= if @live_action == :edit do %>
        <Containers.card container_class="mx-auto max-w-2xl bg-base-200 shadow-xl">
          <.live_component id="profile_form" module={Profile.ProfileForm} talker={@talker} />
        </Containers.card>
      <% else %>
        <%= if @profile do %>
          <.profile_card profile={@profile} />
        <% else %>
          <.no_profile_card />
        <% end %>
      <% end %>
    </Layouts.app>
    """
  end

  def profile_card(assigns) do
    ~H"""
    <div class="grid md:grid-cols-2 gap-4">
      <Containers.card
        :for={
          {title, config} <- [
            core_details: %{
              container_classes: "row-span-2",
              fields: [:first_name, :last_name, :nickname, :location, :age]
            },
            history: %{fields: [:relationship_status, :education, :profession]},
            interests: %{fields: [:hobbies]}
          ]
        }
        container_class={["bg-base-200 shadow-xl", config[:container_classes]]}
      >
        <:title>
          {Phoenix.Naming.humanize(title)}
        </:title>

        <Containers.list>
          <:item :for={field <- config.fields} title={Phoenix.Naming.humanize(field)}>
            {Map.get(@profile, field)}
          </:item>
        </Containers.list>
      </Containers.card>
    </div>
    """
  end

  def no_profile_card(assigns) do
    ~H"""
    <Containers.card container_class="bg-base-200 shadow-xl max-w-xl mx-auto">
      <:title>
        No Profile Yet
      </:title>

      <Button.button size="btn-xl" patch={~p"/profile/edit"}>Create a profile</Button.button>
    </Containers.card>
    """
  end
end
