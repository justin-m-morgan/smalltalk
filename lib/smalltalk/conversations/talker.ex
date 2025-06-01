defmodule Smalltalk.Conversations.Talker do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Conversations.{Conversation, Profile, ReadReceipt}

  postgres do
    schema "conversations"
    table "talkers"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      primary? true

      change relate_actor(:user)
    end
  end

  attributes do
    uuid_v7_primary_key :id
  end

  relationships do
    belongs_to :user, Smalltalk.Accounts.User
    has_one :profile, Profile

    many_to_many :conversations, Conversation do
      through ReadReceipt
      source_attribute_on_join_resource :talker_id
      destination_attribute_on_join_resource :conversation_id
    end
  end

  identities do
    identity :unique_user, [:user_id]
  end
end
