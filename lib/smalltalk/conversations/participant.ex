defmodule Smalltalk.Conversations.Participant do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query
  alias Smalltalk.Conversations.{Admin, Conversation, Talker}

  postgres do
    schema "conversations"
    table "participants"
    repo Smalltalk.Repo
  end

  actions do
    read :read do
      primary? true

      filter expr(is_nil(left_at))
    end

    read :by_actor do
      filter expr(^actor(:id) == talker_id)
      filter expr(is_nil(left_at))

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end

    read :blocked do
      argument :conversation_id, :uuid_v7

      filter expr(conversation_id == ^arg(:conversation_id))
      filter expr(blocked?)
    end

    read :excluding_presence do
      argument :conversation_id, :uuid_v7
      argument :presence_ids, {:array, :uuid_v7}

      filter expr(conversation_id == ^arg(:conversation_id))
      filter expr(talker_id not in ^arg(:presence_ids))
      filter expr(not blocked?)
    end

    create :join do
      primary? true
      upsert? true
      upsert_identity :unique_talker

      accept [:conversation_id, :approved?]

      change set_attribute(:left_at, nil)

      change relate_actor(:talker)
    end

    update :last_active do
      require_atomic? false
      change set_attribute(:last_active, &DateTime.utc_now/0)
    end

    destroy :soft_delete do
      primary? true
      soft? true
      change set_attribute(:left_at, &DateTime.utc_now/0)
    end

    action :leave do
      argument :conversation_id, :uuid_v7, allow_nil?: false

      run fn input, context ->
        __MODULE__
        |> Ash.Query.filter(
          conversation_id: input.arguments.conversation_id,
          talker_id: context.actor.id
        )
        |> Ash.bulk_destroy(:soft_delete, %{}, actor: context.actor)
        |> case do
          %Ash.BulkResult{errors: nil} ->
            :ok

          %Ash.BulkResult{errors: errors} ->
            errors
        end
      end
    end

    update :block do
      change set_attribute(:blocked?, true)
    end

    update :unblock do
      change set_attribute(:blocked?, false)
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type([:destroy]) do
      authorize_if relates_to_actor_via(:talker)
    end

    policy action([:last_active]) do
      authorize_if relates_to_actor_via(:talker)
    end

    policy action(:leave) do
      # Can't use filter checks with generic actions
      authorize_if always()
    end

    policy action(:unblock) do
      # authorize_if always()
      authorize_if relates_to_actor_via([:conversation, :admins, :talker])
    end

    policy action(:block) do
      authorize_if relates_to_actor_via([:conversation, :admins, :talker])
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :left_at, :datetime
    attribute :last_active, :datetime
    attribute :blocked?, :boolean, default: false
    attribute :approved?, :boolean
  end

  relationships do
    belongs_to :conversation, Conversation, public?: true
    belongs_to :talker, Talker
    belongs_to :approved_by, Admin
  end

  calculations do
    calculate :awaiting_approval?,
              :boolean,
              expr(conversation.type != :public && is_nil(approved?)),
              public?: true

    calculate :is_approved?,
              :boolean,
              expr(conversation.type == :public || approved?)
  end

  identities do
    identity :unique_talker, [:conversation_id, :talker_id]
  end
end
