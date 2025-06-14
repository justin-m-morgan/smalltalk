defmodule Smalltalk.Conversations.Conversation do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Smalltalk.Conversations.{Admin, Message, Participants}

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
      argument :participants, :map, default: %{}
      argument :admins, :map, default: %{}
      accept [:short_name, :description]

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
    attribute :short_name, :string
    attribute :description, :string
  end

  relationships do
    has_many :messages, Message

    has_many :participants, Participants do
      filter expr(is_nil(left_at))
    end

    has_many :admins, Admin
  end
end
