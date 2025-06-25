defmodule SmalltalkWeb.ProfileLive.PreviousUploadsComponent do
  use SmalltalkWeb, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias Smalltalk.Conversations
  alias Smalltalk.Uploads

  @impl true

  def update(%{event: :profile_pic_added}, socket) do
    pagination_opts = socket.assings.pagination_opts
    actor = socket.assings.actor

    socket =
      start_async(
        socket,
        :profile_pics,
        fn ->
          Conversations.my_profile_pics!(%{}, page: pagination_opts, actor: actor)
        end
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    actor = assigns.talker

    talker =
      Ash.reload!(assigns.talker,
        load: [:profile],
        actor: actor
      )

    pagination_opts = [offset: 0, limit: 10, count: true]

    socket =
      assign(socket,
        actor: actor,
        talker: talker,
        profile: talker.profile,
        current_profile_pic: talker.current_profile_pic,
        pagination_opts: pagination_opts,
        page: AsyncResult.loading()
      )
      |> start_async(
        :profile_pics,
        fn ->
          Conversations.my_profile_pics!(%{}, page: pagination_opts, actor: actor)
        end
      )

    {:ok, socket}
  end

  @impl true
  def handle_async(:profile_pics, {:ok, async_fun_result}, socket) do
    {:noreply, assign_page_and_stream_results(socket, async_fun_result)}
  end

  defp assign_page_and_stream_results(socket, async_fun_result) do
    socket
    |> assign(page: AsyncResult.ok(%{async_fun_result | results: []}))
    |> stream(:profile_pics, async_fun_result.results, reset: true)
  end

  @impl true
  def handle_event("make_current", %{"profile_pic_id" => profile_pic_id}, socket) do
    talker =
      Conversations.set_current_profile_pic!(
        socket.assigns.talker,
        %{current_profile_pic_id: profile_pic_id},
        actor: socket.assigns.actor
      )

    actor = socket.assigns.actor
    pagination_opts = socket.assigns.pagination_opts

    socket =
      socket
      |> assign(talker: talker)
      |> start_async(
        :profile_pics,
        fn ->
          Conversations.my_profile_pics!(%{}, page: pagination_opts, actor: actor)
        end
      )
      |> put_flash(:success, "Current profile pic updated!")

    {:noreply, socket}
  end

  @impl true
  def handle_event("results-navigate", params, socket) do
    direction = params["direction"] && String.to_existing_atom(params["direction"])
    page_number = params["page_number"] && String.to_integer(params["page_number"])

    page = Ash.page!(socket.assigns.page.result, (direction || page_number) |> dbg()) |> dbg()

    socket =
      socket
      |> assign_page_and_stream_results(page)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Containers.card container_class="bg-base-200 shadow-xl">
        <:title>Previous Uploads</:title>
        <.async_result :let={page} assign={@page}>
          <:loading>
            Loading profile pictures...
          </:loading>
          <div
            class="grid grid-cols-2 lg:grid-cols-5 lg:grid-rows-2 gap-4 p-8"
            phx-update="stream"
            id="profile-pics-stream"
          >
            <div
              :for={{dom_id, profile_pic} <- @streams.profile_pics}
              id={dom_id}
              class="flex justify-center"
            >
              <.pic_preview
                click_event="make_current"
                profile_pic={profile_pic}
                size="size-64"
                current?={profile_pic.id == @talker.current_profile_pic_id}
                target={@myself}
              />
            </div>
          </div>
          <p class="hidden only:block text-center col-span-full py-12 text-3xl font-bold">
            No uploads yet
          </p>
          <.pagination :if={page.count > @pagination_opts[:limit]} myself={@myself} page={page} />
        </.async_result>
      </Containers.card>
    </div>
    """
  end

  attr :target, :any, required: true
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
            src={Uploads.image_path!(@profile_pic.original_src, :original)}
            class={["h-full object-cover "]}
          />
        </div>
        <Icon.icon
          :if={@current?}
          name="hero-check-circle-solid"
          class="size-24 absolute left-0 text-success"
        />
        <Icon.icon
          :if={@current?}
          name="hero-check-circle"
          class="size-24 absolute left-0 text-white"
        />
      </div>
      <div
        :if={!@current?}
        }
        class="col-start-1 row-start-1 col-end-1 row-end-1 z-10 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <Button.button
          type="button"
          phx-target={@target}
          phx-click={@click_event}
          phx-value-profile_pic_id={@profile_pic.id}
        >
          Make Current
        </Button.button>
      </div>
    </div>
    """
  end

  attr :page, :map, required: true
  attr :myself, :any, required: true

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(:current_page, floor(assigns.page.offset / assigns.page.limit))
      |> assign(:page_count, ceil(assigns.page.count / assigns.page.limit))

    ~H"""
    <div class="flex justify-between">
      <Button.button
        type="button"
        phx-click="results-navigate"
        phx-value-direction="prev"
        phx-target={@myself}
        disabled={@page.offset == 0}
      >
        Previous Page
      </Button.button>

      <div class="flex flex-col items-center gap-4">
        <div class="join">
          <button
            :for={page_number <- 1..@page_count}
            :if={@page_count > 1}
            phx-click="results-navigate"
            phx-value-page_number={page_number}
            phx-target={@myself}
            class="join-item btn"
          >
            {page_number}
          </button>
        </div>
        <p>
          Showing {@page.offset + 1} - {min(@page.count, @page.offset + @page.limit)} of {@page.count}
        </p>
      </div>
      <Button.button
        type="button"
        phx-click="results-navigate"
        phx-value-direction="next"
        phx-target={@myself}
        disabled={!@page.more?}
      >
        Next Page
      </Button.button>
    </div>
    """
  end
end
