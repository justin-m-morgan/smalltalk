defmodule SmalltalkWeb.FriendsLive.Index do
  use SmalltalkWeb, :live_view

  alias Smalltalk.Conversations
  alias SmalltalkWeb.Components.EasyTable

  require Logger

  def mount(_params, _session, socket) do
    actor = socket.assigns.talker

    socket =
      socket
      |> assign(actor: actor)

    {:ok, socket}
  end

  def handle_event("unfriend", %{"talker_id" => talker_id, "dom_id" => dom_id}, socket) do
    actor = socket.assigns.actor

    {:ok, request} =
      Conversations.get_friend_request(talker_id,
        query: [filter: [status: :accepted]],
        actor: actor
      )

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
      <div class="flex flex-col gap-4">
        <Containers.header>
          Friends
          <:subtitle>Review Your Current Friends</:subtitle>
          <:actions></:actions>
        </Containers.header>

        <.live_component
          id="friends-table"
          module={EasyTable}
          resource={Smalltalk.Conversations.Talker}
          read_action={:friend}
          opts={[actor: @talker, load: [:email, :full_name, :current_profile_pic_source]]}
          default_sort={{:full_name, :asc}}
          search_pattern={fn query -> [contains: query] end}
          actor={@talker}
          striped?={true}
          limit={15}
          size="table-xl"
        >
          <:caption>
            Friends
          </:caption>

          <:col :let={friend} label="Name" sort_key={:full_name}>
            <div class="grid items-center grid-cols-[40px_1fr] gap-2">
              <DataBlocks.avatar
                src={friend.current_profile_pic_source}
                image_type={:thumbnail}
                alt_text={friend.full_name <> " Profile Pic"}
              />

              {friend.full_name}
            </div>
          </:col>
          <:col :let={friend} label="Email" sort_key={:email}>
            {friend.email}
          </:col>

          <:action :let={{dom_id, friend}}>
            <Button.button
              type="button"
              phx-click="unfriend"
              phx-value-talker_id={friend.id}
              phx-value-dom_id={dom_id}
            >
              Unfriend
            </Button.button>
          </:action>
        </.live_component>
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
