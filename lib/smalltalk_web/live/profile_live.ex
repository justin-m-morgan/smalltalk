defmodule SmalltalkWeb.ProfileLive do
  alias Smalltalk.Uploads
  alias Smalltalk.Uploads.ImageProcessor
  use SmalltalkWeb, :live_view

  alias Smalltalk.Conversations
  alias SmalltalkWeb.Components.Profile

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker
    talker = reload_talker!(socket.assigns.talker)

    socket =
      assign(socket,
        actor: actor,
        profile: talker.profile,
        profile_pics: talker.profile_pics,
        current_profile_pic: talker.current_profile_pic
      )

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

  def handle_info(:image_saved, socket) do
    talker = reload_talker!(socket.assigns.talker)

    socket =
      socket
      |> assign(live_action: nil, profile_pics: talker.profile_pics)
      |> push_patch(to: ~p"/profile")
      |> put_flash(:success, "Image saved successfully!")

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
          <div class="flex gap-1">
            <Button.button
              :for={
                {key, opts} <- [
                  nil: %{
                    patch: ~p"/profile",
                    icon: "hero-user-solid",
                    label: "View Profile"
                  },
                  upload_img: %{
                    patch: ~p"/profile/upload_img",
                    icon: "hero-cloud-arrow-up-solid",
                    label: "Upload Image"
                  },
                  previous_uploads: %{
                    patch: ~p"/profile/previous_uploads",
                    icon: "hero-rectangle-stack-solid",
                    label: "Previous Uploads"
                  },
                  edit: %{
                    patch: ~p"/profile/edit",
                    icon: "hero-list-bullet",
                    label:
                      if(@profile,
                        do: "Update Profile",
                        else: "Create a profile"
                      )
                  }
                ]
              }
              :if={@profile && @live_action != key}
              size="btn-lg"
              patch={opts.patch}
              class="size-8"
            >
              <Icon.icon name={opts.icon} class="size-8" />
              {opts.label}
            </Button.button>
          </div>
        </:actions>
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
          <%= case @live_action do %>
            <% :edit -> %>
              <Containers.card container_class="mx-auto max-w-2xl bg-base-200 shadow-xl">
                <.live_component id="profile_form" module={Profile.ProfileForm} talker={@talker} />
              </Containers.card>
            <% :upload_img -> %>
              <.live_component
                id="profile_image_uploader"
                module={Profile.ImageUpload}
                upload_key={:avatar}
                actor={@talker}
              />
            <% :previous_uploads -> %>
              <Containers.card container_class="bg-base-200 shadow-xl">
                <:title>Previous Uploads</:title>
                <div class="grid grid-cols-2 lg:grid-cols-3 gap-4">
                  <p class="hidden only:block text-center col-span-full py-12 text-3xl font-bold">
                    No uploads yet
                  </p>
                  <div :for={profile_pic <- @profile_pics} class="flex justify-center">
                    <.pic_preview profile_pic={profile_pic} size="size-64" />
                  </div>
                </div>
              </Containers.card>
            <% _ -> %>
              <.profile_card profile={@profile} current_profile_pic={@current_profile_pic} />
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :profile_pic, Conversations.ProfilePic, required: true
  attr :source_type, :atom, values: Uploads.ImageTag.values(), default: :thumbnail
  attr :size, :string, default: "size-96"

  def pic_preview(assigns) do
    ~H"""
    <div class="avatar">
      <div class={["rounded-full shadow-xl", @size]}>
        <img
          src={ImageProcessor.image_path(@profile_pic.original_src, @source_type)}
          class="h-full object-cover"
        />
      </div>
    </div>
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

  def reload_talker!(actor) do
    Ash.reload!(actor,
      load: [:profile, :current_profile_pic, :profile_pics],
      actor: actor
    )
  end
end
