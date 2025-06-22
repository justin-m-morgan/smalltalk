defmodule Smalltalk.Conversations.FriendshipRequest do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Smalltalk.Conversations.Talker

  postgres do
    schema "conversations"
    table "friendship_requests"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read]

    read :by_talker_id do
      argument :talker_id, :string, allow_nil?: false

      filter expr(
               (requested_id == ^arg(:talker_id) && requester_id == ^actor(:id)) or
                 (requester_id == ^arg(:talker_id) && requested_id == ^actor(:id))
             )
    end

    read :accepted do
      filter expr(:status == :accepted)
    end

    read :inbound do
      filter expr(requested_id == ^actor(:id))

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end

    read :outbound do
      filter expr(requester_id == ^actor(:id))

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end

    destroy :cancel do
      primary? true
    end

    destroy :unfriend do
      soft? true
      require_atomic? false

      validate fn changeset, _context ->
        status = Ash.Changeset.get_data(changeset, :status)

        if status == :accepted,
          do: :ok,
          else: {:error, field: :status, message: "can only unfriend accepted requests"}
      end

      change set_attribute(:status, :unfriended)
      change set_attribute(:unfriended_at, &DateTime.utc_now/0)
      change relate_actor(:unfriended_by)
    end

    create :create do
      upsert? true
      upsert_identity :unique_pair

      accept [:requested_id]

      change relate_actor(:requester)
    end

    update :accept do
      change set_attribute(:status, :accepted)
      change set_attribute(:accepted_at, &DateTime.utc_now/0)
    end

    update :reject do
      change set_attribute(:status, :rejected)
      change set_attribute(:rejected_at, &DateTime.utc_now/0)
    end
  end

  policies do
    policy action([:cancel]) do
      authorize_if expr(status == :pending)
      authorize_if relates_to_actor_via(:requester)
    end

    policy action([:accept, :reject]) do
      authorize_if relates_to_actor_via(:requested)
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type([:update, :read, :destroy]) do
      authorize_if relates_to_actor_via(:requester)
      authorize_if relates_to_actor_via(:requested)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :status, :friendship_request_status, default: :pending, public?: true
    attribute :accepted_at, :utc_datetime
    attribute :rejected_at, :utc_datetime
    attribute :unfriended_at, :utc_datetime
  end

  relationships do
    belongs_to :requester, Talker, public?: true
    belongs_to :requested, Talker, public?: true
    belongs_to :unfriended_by, Talker
  end

  calculations do
    calculate :type,
              :atom,
              expr(
                cond do
                  requester_id == ^actor(:id) -> :outbound
                  requested_id == ^actor(:id) -> :inbound
                  true -> :unrelated
                end
              )
  end

  identities do
    identity :unique_pair, [:requester_id, :requested_id]
  end
end
