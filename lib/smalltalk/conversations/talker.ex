defmodule Smalltalk.Conversations.Talker do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Smalltalk.Conversations.{Conversation, Profile, Participants, ReadReceipt}

  postgres do
    schema "conversations"
    table "talkers"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    read :me do
    end

    create :create do
      primary? true
      argument :profile, :map, default: %{}

      change relate_actor(:user)
    end
  end

  policies do
    policy action(:me) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end
  end

  attributes do
    uuid_v7_primary_key :id
  end

  relationships do
    belongs_to :user, Smalltalk.Accounts.User
    has_one :profile, Profile

    has_many :read_receipts, ReadReceipt

    many_to_many :conversations, Conversation do
      through Participants
      source_attribute_on_join_resource :talker_id
      destination_attribute_on_join_resource :conversation_id
    end
  end

  identities do
    identity :unique_user, [:user_id]
  end
end
