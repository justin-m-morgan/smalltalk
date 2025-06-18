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

    read :mine do
      filter expr(participants.talker_id == ^actor(:id))
    end

    create :create do
      primary? true
      argument :participants, :map, default: %{approved?: true}
      argument :admins, :map, default: %{}
      accept [:short_name, :description, :type]

      change manage_relationship(:participants, type: :create)
      change manage_relationship(:admins, type: :create)
    end
  end

  policies do
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
    end

    has_many :admins, Admin
  end
end
