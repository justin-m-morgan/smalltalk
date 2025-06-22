defmodule SmalltalkWeb.ProfileLive.PreviousUploads do
  use SmalltalkWeb, :live_view

  alias Smalltalk.Conversations
  alias Smalltalk.Uploads
  alias Smalltalk.Uploads.ImageProcessor

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    talker =
      Ash.reload!(socket.assigns.talker,
        load: [:profile, :profile_pics],
        actor: actor
      )

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
  def handle_event("make_current", %{"profile_pic_id" => profile_pic_id}, socket) do
    talker =
      Conversations.set_current_profile_pic!(
        socket.assigns.talker,
        %{current_profile_pic_id: profile_pic_id},
        actor: socket.assigns.actor
      )

    socket =
      socket
      |> assign(talker: talker)
      |> put_flash(:success, "Current profile pic updated!")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:profile}
      active_sub_tab={:previous_uploads}
      current_user={@current_user}
      talker={@talker}
    >
      <Containers.header>
        Profile
      </Containers.header>

      <Containers.card container_class="bg-base-200 shadow-xl">
        <:title>Previous Uploads</:title>
        <div class="grid grid-cols-2 lg:grid-cols-3 gap-4">
          <p class="hidden only:block text-center col-span-full py-12 text-3xl font-bold">
            No uploads yet
          </p>
          <div :for={profile_pic <- @profile_pics} class="flex justify-center">
            <.pic_preview
              click_event="make_current"
              profile_pic={profile_pic}
              size="size-64"
              current?={profile_pic.id == @talker.current_profile_pic_id}
            />
          </div>
        </div>
      </Containers.card>
    </Layouts.app>
    """
  end

  attr :click_event, :string, required: true
  attr :current?, :boolean, default: false
  attr :profile_pic, Conversations.ProfilePic, required: true
  attr :source_type, :atom, values: Uploads.ImageTag.values(), default: :thumbnail
  attr :size, :string, default: "size-96"

  def pic_preview(assigns) do
    ~H"""
    <div class="grid place-items-center isolate group">
      <div class={[
        "avatar relative col-start-1 row-start-1 col-end-1 row-end-1 transition-all",
        if(!@current?, do: "group-hover:blur-lg")
      ]}>
        <div class={["rounded-full shadow-xl", @size]}>
          <img
            src={ImageProcessor.image_path(@profile_pic.original_src, @source_type)}
            class={["h-full object-cover "]}
          />
        </div>
        <Icon.icon
          :if={@current?}
          name="hero-check-circle-solid"
          class="size-24 absolute right-0 text-success"
        />
        <Icon.icon
          :if={@current?}
          name="hero-check-circle"
          class="size-24 absolute right-0 text-white"
        />
      </div>
      <div
        :if={!@current?}
        }
        class="col-start-1 row-start-1 col-end-1 row-end-1 z-10 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <Button.button
          type="button"
          phx-click={@click_event}
          phx-value-profile_pic_id={@profile_pic.id}
        >
          Make Current
        </Button.button>
      </div>
    </div>
    """
  end
end
