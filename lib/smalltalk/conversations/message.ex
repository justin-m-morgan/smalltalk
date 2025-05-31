defmodule Smalltalk.Conversations.Message do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Conversations.{Conversation, Talker}

  postgres do
    schema "conversations"
    table "messages"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    read :read_by_conversation_id do
      argument :conversation_id, :uuid_v7, allow_nil?: false

      filter expr(:conversation_id == ^arg(:conversation_id))
    end

    create :create do
      primary? true
      argument :conversation, :struct, allow_nil?: false

      accept [:content]

      change manage_relationship(:conversation, type: :append)
    end
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :content, :string
  end

  relationships do
    belongs_to :conversation, Conversation
    belongs_to :talker, Talker
  end
end
