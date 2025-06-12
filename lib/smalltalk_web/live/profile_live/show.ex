defmodule SmalltalkWeb.ProfileLive.Show do
  use SmalltalkWeb, :live_view

  alias Smalltalk.Conversations
  alias Smalltalk.Uploads

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    talker =
      Ash.reload!(actor,
        load: [:profile, :current_profile_pic],
        actor: actor
      )

    socket =
      assign(socket,
        actor: actor,
        profile: talker.profile,
        current_profile_pic: talker.current_profile_pic
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:profile}
      active_sub_tab={:show}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        Profile
      </Containers.header>

      <div class="grid gap-4">
        <%= if !@profile do %>
          <div class="max-w-lg grid gap-4 mx-auto">
            <.no_profile_card />
            <Containers.card container_class="mx-auto max-w-2xl bg-base-200 shadow-xl">
              <.live_component id="profile_form" module={Profile.ProfileForm} talker={@talker} />
            </Containers.card>
          </div>
        <% else %>
          <.profile_card profile={@profile} current_profile_pic={@current_profile_pic} />
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :current_profile_pic, Conversations.ProfilePic
  attr :profile, Conversations.Profile, required: true

  def profile_card(assigns) do
    ~H"""
    <div class="grid md:grid-cols-2 gap-4">
      <div class="col-span-full mx-auto">
        <%= if !@current_profile_pic do %>
          <div class="size-96 bg-base-200 rounded-full shadow-xl">
            <Icon.icon name="hero-user" class="size-96" />
          </div>
        <% else %>
          <.pic_preview profile_pic={@current_profile_pic} source_type={:medium} />
        <% end %>
      </div>

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

  attr :profile_pic, Conversations.ProfilePic, required: true
  attr :source_type, :atom, values: Uploads.ImageTag.values(), default: :thumbnail
  attr :size, :string, default: "size-96"

  def pic_preview(assigns) do
    ~H"""
    <div class="avatar">
      <div class={["rounded-full shadow-xl ", @size]}>
        <img
          src={Uploads.image_path!(@profile_pic.original_src, @source_type)}
          class="h-full object-cover"
        />
      </div>
    </div>
    """
  end

  def no_profile_card(assigns) do
    ~H"""
    <Containers.card container_class="bg-base-200 shadow-xl">
      <:title>
        No Profile Yet
      </:title>

      <p>You must create a profile before gaining access to much of Smalltalk's functionality.</p>
    </Containers.card>
    """
  end
end
