defmodule Smalltalk.Conversations.Conversation do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Smalltalk.Conversations.{Admin, Message, Participant}

  postgres do
    schema "conversations"
    table "conversations"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    read :search do
      filter expr(type != :secret)

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end

    read :mine do
      filter expr(participants.talker_id == ^actor(:id))

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end

    create :create do
      primary? true
      argument :participants, :map, default: %{approved?: true}
      argument :admins, :map, default: %{}
      accept [:short_name, :description, :type]

      change manage_relationship(:participants, type: :create)
      change manage_relationship(:admins, type: :create)
    end

    update :assign_admin do
      require_atomic? false
      argument :admins, :map, allow_nil?: false

      change manage_relationship(:admins, type: :create, on_no_match: {:create, :assign})
    end
  end

  policies do
    policy action(:assign_admin) do
      authorize_if relates_to_actor_via([:admins, :talker])
    end

    policy always() do
      authorize_if always()
    end
  end

  validations do
    validate string_length(:short_name, min: 1, max: 60),
      message: "Keep it short. Put more detail in the description"
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :short_name, :string, public?: true
    attribute :description, :string, public?: true
    attribute :type, :conversation_type, default: :public, public?: true
  end

  relationships do
    has_many :messages, Message

    has_many :participants, Participant do
      filter expr(is_nil(left_at))
      public? true
    end

    has_many :admins, Admin, public?: true
  end

  calculations do
    calculate :approved?,
              :boolean,
              expr(participants.talker_id == ^actor(:id) && participants.approved?),
              public?: true

    calculate :awaiting_approval?,
              :boolean,
              expr(participants.talker_id == ^actor(:id) && participants.awaiting_approval?),
              public?: true

    calculate :status,
              :atom,
              expr(
                cond do
                  awaiting_approval? -> :awaiting_approval
                  approved? -> :approved
                  approved? == false -> :rejected
                end
              ),
              public?: true
  end

  aggregates do
    exists :is_admin?, :admins do
      filter expr(talker_id == ^actor(:id))
      public? true
    end
  end
end
