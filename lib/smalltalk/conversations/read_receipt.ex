defmodule Smalltalk.Conversations.ReadReceipt do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Conversations.{Conversation, Message, Talker}

  postgres do
    schema "conversations"
    table "read_receipts"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :mark_as_read do
      primary? true
      upsert? true
      upsert_identity :unique_talker_conversation
      argument :message, :struct, allow_nil?: false

      change relate_actor(:talker)

      change fn changeset, context ->
        message = Ash.Changeset.get_argument(changeset, :message)

        changeset
        |> Ash.Changeset.change_attribute(:conversation_id, message.conversation_id)
        |> Ash.Changeset.change_attribute(:most_recent_message_id, message.id)
      end
    end
  end

  attributes do
    uuid_v7_primary_key :id
  end

  relationships do
    belongs_to :talker, Talker, allow_nil?: false
    belongs_to :conversation, Conversation, allow_nil?: false
    belongs_to :most_recent_message, Message
  end

  identities do
    identity :unique_talker_conversation, [:talker_id, :conversation_id]
  end
end
