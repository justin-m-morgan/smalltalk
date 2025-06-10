defmodule SmalltalkWeb.FriendsLive.Requests do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations

  require Logger

  @request_preloads [requested: [:email], requester: [:email]]

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    socket =
      socket
      |> assign(actor: actor)
      |> stream_async(:inbound_requests, fn ->
        Conversations.inbound_friend_requests!(
          load: @request_preloads,
          actor: actor
        )
      end)
      |> stream_async(:outbound_requests, fn ->
        Conversations.outbound_friend_requests!(
          load: @request_preloads,
          actor: actor
        )
      end)

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
        <.async_result :let={stream_key} assign={@inbound_requests}>
          <:loading>Loading Inbound Requests...</:loading>
          <.table
            actor_id={@actor.id}
            rows={@streams[stream_key]}
            id="inbound-requests-table"
            table_title="Inbound Requests"
            actions={[
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
            ]}
          />
        </.async_result>
        <.async_result :let={stream_key} assign={@outbound_requests}>
          <:loading>Loading Outbound Requests...</:loading>
          <.table
            actor_id={@actor.id}
            rows={@streams[stream_key]}
            id="outbound-requests-table"
            table_title="Outbound Requests"
            actions={[
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
            ]}
          />
        </.async_result>
      </div>
    </Layouts.app>
    """
  end

  attr :actor_id, :string, required: true
  attr :rows, :any, required: true
  attr :table_title, :string, required: true
  attr :id, :string, required: true

  attr :actions, :list, required: true

  def table(assigns) do
    ~H"""
    <div>
      <Table.table id={@id} rows={@rows} th_classes="nth-2:w-[200px]">
        <:caption>{@table_title}</:caption>
        <:col :let={{_dom_id, request}} label="Email">
          {find_other_party_email(request, @actor_id)}
        </:col>
        <:col :let={{_dom_id, request}} label="Status">
          {Phoenix.Naming.humanize(request.status)}
        </:col>
        <:col :let={{_dom_id, request}} label="Sent at">
          {Smalltalk.UuidDatable.extract_and_format_timestamp(request.id)}
        </:col>
        <:action :let={{dom_id, request}}>
          <Button.button
            :for={{key, opts} <- @actions}
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
      </Table.table>
    </div>
    """
  end

  defp find_other_party_email(request, actor_id) do
    [request.requester, request.requested]
    |> Enum.find(&(&1.id != actor_id))
    |> Map.get(:email)
  end
end
