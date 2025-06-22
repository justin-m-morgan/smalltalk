defmodule Smalltalk.Conversations.Admin do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Conversations.{Conversation, Talker}

  postgres do
    schema "conversations"
    table "admins"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy]

    read :by_actor do
      filter expr(talker_id == ^actor(:id))
    end

    read :for_conversation do
      argument :conversation_id, :uuid_v7, allow_nil?: false
      filter expr(conversation_id == ^arg(:conversation_id))
    end

    create :create do
      primary? true
      change relate_actor(:talker)
    end

    create :assign do
      argument :talker, :struct, allow_nil?: false

      change manage_relationship(:talker, type: :append)
    end
  end

  attributes do
    uuid_v7_primary_key :id
  end

  relationships do
    belongs_to :conversation, Conversation
    belongs_to :talker, Talker, public?: true
  end
end
