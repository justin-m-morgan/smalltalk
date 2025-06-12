defmodule SmalltalkWeb.FriendsLive.Index do
  use SmalltalkWeb, :live_view
  use LiveStreamAsync

  alias Smalltalk.Conversations

  require Logger

  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    socket =
      socket
      |> assign(actor: actor)
      |> stream_async(:friends, fn ->
        Conversations.all_friends!(load: [:email, :profile], actor: actor)
      end)

    {:ok, socket}
  end

  def handle_event("unfriend", %{"talker_id" => talker_id, "dom_id" => dom_id}, socket) do
    actor = socket.assigns.actor

    {:ok, request} =
      Conversations.get_friend_request(talker_id,
        query: [filter: [status: :accepted]],
        actor: actor
      )
      |> dbg()

    socket =
      case Conversations.unfriend(request, actor: actor) do
        {:ok, _request} ->
          socket
          |> put_flash(:success, "Unfriended")
          |> stream_delete_by_dom_id(:friends, dom_id)

        {:error, error} ->
          Logger.error(error)

          socket
          |> put_flash(:error, "Something went wrong.")
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      active_tab={:friends}
      active_sub_tab={:current}
      current_user={@current_user}
      talker={@talker}
    >
      <div class="flex flex-col gap-16">
        <Containers.header>
          Friends
          <:subtitle>Review Your Current Friends</:subtitle>
          <:actions></:actions>
        </Containers.header>

        <.async_result :let={stream_key} assign={@friends}>
          <:loading>Loading Friends...</:loading>
          <.table rows={@streams[stream_key]} id="friends-table" table_title="Friends" />
        </.async_result>
      </div>
    </Layouts.app>
    """
  end

  attr :rows, :any, required: true
  attr :table_title, :string, required: true
  attr :id, :string, required: true

  def table(assigns) do
    ~H"""
    <div>
      <h3 class="text-xl font-bold">{@table_title}</h3>
      <Table.table id={@id} rows={@rows}>
        <:col :let={{_dom_id, talker}} label="Name">{talker.profile.first_name}</:col>
        <:col :let={{_dom_id, talker}} label="Email">{talker.email}</:col>
        <:action :let={{dom_id, talker}}>
          <Button.button
            type="button"
            phx-click="unfriend"
            phx-value-talker_id={talker.id}
            phx-value-dom_id={dom_id}
          >
            Unfriend
          </Button.button>
        </:action>
      </Table.table>
    </div>
    """
  end
end
