defmodule SmalltalkWeb.FriendsLive.Search do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Phoenix.LiveView.JS
  alias Smalltalk.Conversations
  alias SmalltalkWeb.Components.EasyTable

  require Logger

  @talker_preloads [
    :email,
    :full_name,
    :current_profile_pic_source,
    :inbound_friendship_requests,
    :outbound_friendship_requests
  ]

  @impl true
  def handle_params(_params, _uri, socket) do
    actor = socket.assigns.talker

    socket =
      socket
      |> assign(
        actor: actor,
        send_friend_request_event: "send_friend_request",
        send_friend_request_key: "talker_id"
      )

    {:noreply, socket}
  end

  @impl true

  def handle_event("send_friend_request", %{"talker_id" => talker_id}, socket) do
    actor = socket.assigns.actor

    socket =
      case Conversations.send_friend_request(%{requested_id: talker_id},
             actor: actor,
             load: [requested: @talker_preloads]
           ) do
        {:ok, request} ->
          send_update(EasyTable, %{
            id: "friends-table",
            event: %{name: :update_item, payload: request}
          })

          socket
          # |> stream_insert(:friends, request.requested)
          |> put_flash(:success, "Friend request sent")

        {:error, error} ->
          Logger.error(error)

          socket
          |> put_flash(:error, "Failed to send friend request")
      end

    {:noreply, socket}
  end

  attr :talker_preloads, :list, default: @talker_preloads
  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:friends}
      active_sub_tab={:search}
      current_user={@current_user}
      talker={@talker}
    >
      <div class="flex flex-col gap-4">
        <Containers.header>
          Friend Candidates
          <:subtitle>Search for friends</:subtitle>
        </Containers.header>

        <.live_component
          id="friends-table"
          module={EasyTable}
          resource={Smalltalk.Conversations.Talker}
          read_action={:read}
          opts={[actor: @talker, load: @talker_preloads]}
          default_sort={{:full_name, :asc}}
          actor={@talker}
          striped?={true}
          searchable_fields={[:email]}
          limit={15}
          size="table-xl"
        >
          <:caption>
            Friends
          </:caption>

          <:col :let={talker} label="Name" sort_key={:full_name}>
            <div class="grid grid-cols-[40px_1fr] items-center gap-2">
              <DataBlocks.avatar
                src={talker.current_profile_pic_source}
                image_type={:thumbnail}
                alt_text={talker.full_name <> " Profile Pic"}
              />
              {talker.full_name}
            </div>
          </:col>

          <:col :let={talker} label="Email">{talker.email}</:col>

          <:action :let={{_dom_id, talker}}>
            <% status = friend_status(talker, @actor) %>

            <Button.button
              :if={status == :not_friends}
              phx-click={
                JS.push(@send_friend_request_event,
                  value: Map.new([{@send_friend_request_key, talker.id}])
                )
              }
              phx-value-talker_id={talker.id}
            >
              <Icon.icon name="hero-user-plus-solid" class="size-6" /> Add Friend
            </Button.button>
            <.status
              :for={
                {key, opts} <- [
                  requested: %{icon: "hero-clock", color: "badge-accent"},
                  friends: %{icon: "hero-check-circle", color: "badge-success"},
                  me: %{icon: "hero-user-solid", color: "badge-neutral"}
                ]
              }
              :if={status == key}
              color={opts.color}
              icon={opts.icon}
            >
              {key
              |> Phoenix.Naming.humanize()
              |> String.capitalize()}
            </.status>
          </:action>
        </.live_component>
      </div>
    </Layouts.app>
    """
  end

  attr :icon, :string, required: true
  attr :color, :string, required: true
  slot :inner_block, required: true

  def status(assigns) do
    ~H"""
    <Indicators.badge color={@color} size="badge-xl" class="rounded-full">
      <Icon.icon name={@icon} class="size-6" /> {render_slot(@inner_block)}
    </Indicators.badge>
    """
  end

  attr :query_change_event, :string, required: true
  attr :query_field_name, :string, required: true

  def search_form(assigns) do
    ~H"""
    <form phx-change={@query_change_event}>
      <fieldset class="fieldset flex flex-col">
        <label class="label" for={@query_field_name}>
          Search by email
        </label>
        <input
          id={@query_field_name}
          phx-debounce={200}
          type="text"
          name={@query_field_name}
          class="input"
          placeholder="Search for email..."
        />
      </fieldset>
    </form>
    """
  end

  def friend_status(talker, actor) do
    requests =
      Enum.concat(talker.inbound_friendship_requests, talker.outbound_friendship_requests)
      |> Enum.filter(&(&1.requester_id == actor.id || &1.requested_id == talker.id))

    cond do
      talker.id == actor.id -> :me
      not Enum.any?(requests) -> :not_friends
      Enum.any?(requests, &(&1.status == :accepted)) -> :friends
      true -> :requested
    end
  end
end
