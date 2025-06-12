defmodule SmalltalkWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :smalltalk,
    pubsub_server: Smalltalk.PubSub

  alias Smalltalk.Conversations

  def init(_opts) do
    {:ok, %{}}
  end

  def fetch("online_users", presences) do
    limited_talker_data = fetch_all_users(presences)

    for {key, %{metas: [meta | metas]}} <- presences, into: %{} do
      # user can be populated here from the database here we populate
      # the name for demonstration purposes

      {key, %{metas: [meta | metas], id: meta.id, user: Map.get(limited_talker_data, key)}}
    end
  end

  def fetch("conversation:" <> conversation_id, presences) do
    limited_talker_data = fetch_all_users(presences)

    for {key, %{metas: [meta | metas]}} <- presences, into: %{} do
      # user can be populated here from the database here we populate
      # the name for demonstration purposes

      {key, %{metas: [meta | metas], id: meta.id, user: Map.get(limited_talker_data, key)}}
    end
  end

  defp fetch_all_users(presences, load \\ [:full_name, :current_profile_pic_source]) do
    ids = Enum.map(presences, fn {id, _} -> id end)

    Conversations.all_talkers!(
      query: [filter: [id: [in: ids]]],
      load: load
    )
    |> then(&Map.new(&1, fn talker -> {talker.id, Map.take(talker, [:id | load])} end))
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, presence} <- joins do
      user_data = %{id: user_id, user: presence.user, metas: Map.fetch!(presences, user_id)}
      msg = {__MODULE__, {:join, user_data}}
      Phoenix.PubSub.local_broadcast(Smalltalk.PubSub, "proxy:#{topic}", msg)
    end

    for {user_id, presence} <- leaves do
      metas =
        case Map.fetch(presences, user_id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      user_data = %{id: user_id, user: presence.user, metas: metas}
      msg = {__MODULE__, {:leave, user_data}}
      Phoenix.PubSub.local_broadcast(Smalltalk.PubSub, "proxy:#{topic}", msg)
    end

    {:ok, state}
  end

  # Client Functions

  def list_online_users(topic \\ "online_users"),
    do: topic |> list() |> Enum.map(fn {_id, presence} -> presence.user end)

  def track_user(name, params, topic \\ "online_users"), do: track(self(), topic, name, params)

  def subscribe(topic \\ "online_users"),
    do: Phoenix.PubSub.subscribe(Smalltalk.PubSub, "proxy:#{topic}")
end
