defmodule Smalltalk.Conversations.Message do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  alias Smalltalk.Conversations.{Conversation, ReadReceipt, Talker}

  postgres do
    schema "conversations"
    table "messages"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    read :read_by_conversation_id do
      prepare build(sort: [id: :desc])

      pagination do
        required? false
        offset? true
      end

      argument :conversation_id, :uuid_v7, allow_nil?: false
      filter expr(conversation_id == ^arg(:conversation_id))
    end

    create :create do
      primary? true

      accept [:content, :conversation_id]

      change relate_actor(:talker)
    end

    action :subscribe_to_new_messages, :string do
      argument :conversation_id, :uuid_v7, allow_nil?: false

      run fn %{arguments: %{conversation_id: conversation_id}}, _ ->
        topic = "messages:conversation:#{conversation_id}"
        Phoenix.PubSub.subscribe(Smalltalk.PubSub, topic)

        {:ok, topic}
      end
    end
  end

  pub_sub do
    module SmalltalkWeb.Endpoint

    publish :create, ["messages", "conversation", :conversation_id]
  end

  validations do
    validate present(:content)
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :content, :string do
      allow_nil? false

      constraints min_length: 1,
                  trim?: true,
                  allow_empty?: false
    end
  end

  relationships do
    belongs_to :conversation, Conversation, public?: true
    belongs_to :talker, Talker
    has_many :read_receipts, ReadReceipt, destination_attribute: :most_recent_message_id
  end
end
