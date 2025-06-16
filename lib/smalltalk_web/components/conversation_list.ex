defmodule SmalltalkWeb.Components.ConversationList do
  use SmalltalkWeb, :live_component
  use LiveStreamAsync

  alias Smalltalk.Conversations

  require Logger

  @conversation_preloads [participants: [talker: [:full_name, :current_profile_pic_source]]]

  @impl true
  def update(assigns, socket) do
    actor = assigns.actor
    {module, func, args} = assigns.action

    socket =
      socket
      |> assign(assigns)
      |> assign(actor: actor)
      |> assign_new(:display_mode, fn -> :table end)
      |> stream_async(:conversations, fn ->
        apply(module, func, [%{}, args])
        |> Enum.map(fn
          %Conversations.Conversation{} = c -> c
          tangential_resource -> tangential_resource.conversation
        end)
      end)

    {:ok, socket}
  end

  def display_mode_toggle(assigns) do
    next_display_mode = if assigns.current_display_mode == "table", do: "cards", else: "table"
    checked = assigns.current_display_mode == "cards"

    uri = URI.parse(assigns.uri)

    query =
      (uri.query || "display_mode=table")
      |> URI.decode_query()
      |> Map.put("display_mode", next_display_mode)
      |> URI.encode_query()

    patch =
      %{uri | query: query}
      |> URI.to_string()

    assigns =
      assign(assigns,
        patch: patch,
        checked: checked
      )

    ~H"""
    <label class="toggle toggle-xl h-full w-18 text-base-content" phx-click={JS.patch(@patch)}>
      <input type="checkbox" checked={@checked} />
      <Icon.icon name="hero-list-bullet" class="size-8" />
      <Icon.icon name="hero-square-2-stack" class="size-8" />
    </label>
    """
  end

  @impl true
  def handle_event("join_conversation", %{"conversation_id" => conversation_id}, socket) do
    actor = socket.assigns.actor

    socket =
      case Conversations.join_conversation(conversation_id, actor: actor) do
        {:ok, _participants} ->
          socket
          |> push_navigate(to: ~p"/conversations?conversation_id=#{conversation_id}")
          |> put_flash(:success, "You joined the conversation!")

        {:error, error} ->
          Logger.error(error)

          socket
          |> put_flash(:error, "Error joining conversation.")
      end

    {:noreply, socket}
  end

  def handle_event(
        "leave_conversation",
        %{"conversation_id" => conversation_id},
        socket
      ) do
    actor = socket.assigns.actor

    socket =
      case Conversations.leave_conversation(conversation_id, actor: actor) do
        :ok ->
          conversation =
            Conversations.get_conversation!(conversation_id,
              load: @conversation_preloads,
              actor: actor
            )

          socket
          |> stream_insert(:conversations, conversation)
          |> put_flash(:success, "You have left the conversation!")

        {:error, error} ->
          Logger.error(error)

          socket
          |> put_flash(:error, "Error leaving conversation.")
      end

    {:noreply, socket}
  end

  slot :actions
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.async_result :let={stream_key} assign={@conversations}>
        <:loading>Loading...</:loading>
        <:failed>Failed to load conversations.</:failed>

        <.conversation_cards
          :if={@display_mode == :cards}
          id={@id <> "-stream"}
          rows={@streams[stream_key]}
        >
          <:actions :let={%{conversation: conversation}}>
            <.action_button
              :for={action <- actions(%{conversation: conversation, actor: @actor})}
              phx-value-conversation_id={conversation.id}
              phx-target={@myself}
              {action}
            />
          </:actions>
        </.conversation_cards>

        <.table :if={@display_mode == :table} rows={@streams[stream_key]} actor_id={@actor.id}>
          <:actions :let={%{conversation: conversation}}>
            <.action_button
              :for={action <- actions(%{conversation: conversation, actor: @actor})}
              phx-value-conversation_id={conversation.id}
              phx-target={@myself}
              {action}
            />
          </:actions>
        </.table>
      </.async_result>
    </div>
    """
  end

  def actions(deps \\ %{}) do
    cond do
      deps.actor.id in Enum.map(deps.conversation.participants, & &1.talker_id) ->
        [
          %{label: "Go To", navigate: ~p"/conversations?conversation_id=#{deps.conversation.id}"},
          %{label: "Leave", "phx-click": "leave_conversation"}
        ]

      true ->
        [
          %{label: "Join", "phx-click": "join_conversation"}
        ]
    end
  end

  attr :id, :string, required: true
  attr :rows, Phoenix.LiveView.LiveStream, required: true
  slot :actions

  def conversation_cards(assigns) do
    ~H"""
    <div
      class="grid gap-4"
      style="grid-template-columns: repeat(auto-fill, minmax(400px, 1fr))"
      phx-update="stream"
      id={@id}
    >
      <Containers.card
        :for={{dom_id, conversation} <- @rows}
        id={dom_id}
        container_class="bg-base-200"
      >
        <Containers.list>
          <:item title="Name">
            <div class="flex justify-between items-center">
              <span>{conversation.short_name}</span>
              <.conversation_type_badge type={conversation.type} />
            </div>
          </:item>
          <:item title="Description">{conversation.description || "No Description Provided"}</:item>
          <:item title="Participants">
            <%= if Enum.any?(conversation.participants) do %>
              <DataBlocks.avatar_group data={conversation.participants}>
                <:avatar_template :let={participant}>
                  <DataBlocks.avatar
                    src={participant.talker.current_profile_pic_source}
                    image_type={:thumbnail}
                    alt_text={"#{participant.talker.full_name}"}
                  />
                </:avatar_template>
              </DataBlocks.avatar_group>
            <% else %>
              <div class="flex items-center gap-2">
                <DataBlocks.avatar_placeholder />
                <span>None Currently</span>
              </div>
            <% end %>
          </:item>
        </Containers.list>
        <:actions>
          <%= if Enum.any?(@actions) do %>
            {render_slot(@actions, %{conversation: conversation, dom_id: dom_id})}
          <% else %>
            No Actions Available
          <% end %>
        </:actions>
      </Containers.card>
    </div>
    """
  end

  attr :actor_id, :string, required: true
  attr :rows, Phoenix.LiveView.LiveStream, required: true
  slot :actions

  defp table(assigns) do
    ~H"""
    <Table.table id="conversations" rows={@rows}>
      <:col :let={{_id, conversation}} label="Short Name">{conversation.short_name}</:col>
      <:col :let={{_id, conversation}} label="Description">{conversation.description}</:col>
      <:col :let={{_id, conversation}} label="Type">
        <.conversation_type_badge type={conversation.type} />
      </:col>
      <:col :let={{_id, conversation}} label="Participants">
        <DataBlocks.avatar_group data={conversation.participants}>
          <:avatar_template :let={participant}>
            <DataBlocks.avatar
              size="size-8"
              src={participant.talker.current_profile_pic_source}
              image_type={:thumbnail}
              alt_text={"#{participant.talker.full_name}"}
            />
          </:avatar_template>
        </DataBlocks.avatar_group>
      </:col>
      <:action :let={{dom_id, conversation}}>
        {render_slot(@actions, %{dom_id: dom_id, conversation: conversation})}
      </:action>
      <:empty_results>
        <div class="flex flex-col items-center gap-16">
          <span>No Conversations</span>
        </div>
      </:empty_results>
    </Table.table>
    """
  end

  attr :label, :string, required: true

  attr :rest, :global, include: ~w/navigate phx-click phx-target phx-value-conversation_id/

  defp action_button(assigns) do
    ~H"""
    <Button.button type="button" size="btn-sm" {@rest}>
      {@label}
    </Button.button>
    """
  end

  attr :type, :atom, values: Conversations.ConversationType.values()

  defp conversation_type_badge(assigns) do
    ~H"""
    <Indicators.badge color={
      case @type do
        :public -> "badge-info"
        :private -> "badge-warning"
        :secret -> "badge-error"
      end
    }>
      {Phoenix.Naming.humanize(@type)}
    </Indicators.badge>
    """
  end
end
