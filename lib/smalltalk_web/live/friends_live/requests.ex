defmodule SmalltalkWeb.FriendsLive.Requests do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations

  require Logger

  alias SmalltalkWeb.Components.EasyTable

  @request_preloads [requested: [:full_name, :email], requester: [:email]]

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    socket =
      socket
      |> assign(actor: actor)

    {:ok, socket}
  end

  @impl true
  def handle_event(event, %{"request_id" => request_id, "dom_id" => dom_id}, socket)
      when event in ["accept", "reject", "cancel"] do
    actor = socket.assigns.actor
    action_name = "#{event}_friend_request" |> String.to_existing_atom()
    request = Ash.get!(Conversations.FriendshipRequest, request_id, authorize?: false)

    socket =
      case apply(Conversations, action_name, [
             request,
             [load: @request_preloads, actor: actor]
           ]) do
        {:ok, request} ->
          socket
          |> put_flash(:success, "Request #{event}ed")
          |> stream_insert(:inbound_requests, request)

        :ok ->
          socket
          |> put_flash(:success, "Request #{event}ed")
          |> stream_delete_by_dom_id(:outbound_requests, dom_id)

        {:error, error} ->
          Logger.error(error)

          socket
          |> put_flash(:error, "Something went wrong.")
      end

    {:noreply, socket}
  end

  attr :request_preloads, :list, default: @request_preloads

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:friends}
      active_sub_tab={:requests}
      current_user={@current_user}
      talker={@talker}
    >
      <div class="flex flex-col gap-16">
        <Containers.header>
          Friend Requests
          <:subtitle>Review Your Friend Requests</:subtitle>
          <:actions></:actions>
        </Containers.header>

        <.live_component
          id="inbound-requests-table"
          module={EasyTable}
          resource={Smalltalk.Conversations.FriendshipRequest}
          read_action={:inbound}
          opts={[actor: @talker, load: [requester: [:full_name, :current_profile_pic_source]]]}
          default_sort={{:id, :asc}}
          actor={@talker}
          striped?={true}
          searchable_fields={[[:requester, :full_name]]}
          limit={15}
          size="table-xl"
          fixed_width_columns?={false}
        >
          <:caption>
            Inbound Requests
          </:caption>

          <:col :let={request} label="Full Name">
            <DataBlocks.avatar
              src={request.requester.current_profile_pic_source}
              alt_text={request.requester.full_name}
            /> {request.requester.full_name}
          </:col>

          <:col :let={request} label="Status">
            {Phoenix.Naming.humanize(request.status)}
          </:col>
          <:col :let={request} label="Sent at">
            <DataBlocks.timestamp id={"#{request.id}-timestamp"} uuid_timestamp={request.id} />
          </:col>

          <:action
            :let={{dom_id, request}}
            :for={
              {key, opts} <- [
                accept: %{
                  label: "Accept",
                  icon: "hero-hand-thumb-up-solid",
                  if: fn request -> request.status == :pending end
                },
                reject: %{
                  label: "Reject",
                  icon: "hero-hand-thumb-down-solid",
                  if: fn request -> request.status == :pending end
                }
              ]
            }
          >
            <Button.button
              :if={!opts[:if] || opts.if.(request)}
              type="button"
              phx-click={key}
              phx-value-request_id={request.id}
              phx-value-dom_id={dom_id}
            >
              <Icon.icon name={opts.icon} class="size-6" />
              {opts.label}
            </Button.button>
          </:action>
        </.live_component>

        <.live_component
          id="outbound-requests-table"
          module={EasyTable}
          resource={Smalltalk.Conversations.FriendshipRequest}
          read_action={:outbound}
          opts={[actor: @talker, load: [requested: [:full_name, :current_profile_pic_source]]]}
          default_sort={{:id, :asc}}
          actor={@talker}
          striped?={true}
          searchable_fields={[[:requested, :full_name]]}
          limit={15}
          size="table-xl"
          fixed_width_columns?={false}
        >
          <:caption>
            Outbound Requests
          </:caption>

          <:col :let={request} label="Full Name">
            <DataBlocks.avatar
              src={request.requested.current_profile_pic_source}
              alt_text={request.requested.full_name}
            /> {request.requested.full_name}
          </:col>

          <:col :let={request} label="Status">
            {Phoenix.Naming.humanize(request.status)}
          </:col>
          <:col :let={request} label="Sent at">
            <DataBlocks.timestamp id={"#{request.id}-timestamp"} uuid_timestamp={request.id} />
          </:col>

          <:action
            :let={{dom_id, request}}
            :for={
              {key, opts} <- [
                cancel: %{
                  label: "Cancel",
                  icon: "hero-x-circle-solid",
                  if: fn request -> request.status == :pending end
                },
                revive: %{
                  label: "Revive",
                  icon: "hero-sparkles-solid",
                  if: fn request -> request.status == :canceled end
                }
              ]
            }
          >
            <Button.button
              :if={!opts[:if] || opts.if.(request)}
              type="button"
              phx-click={key}
              phx-value-request_id={request.id}
              phx-value-dom_id={dom_id}
            >
              <Icon.icon name={opts.icon} class="size-6" />
              {opts.label}
            </Button.button>
          </:action>
        </.live_component>
      </div>
    </Layouts.app>
    """
  end
end
