defmodule Smalltalk.Conversations.Conversation do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Conversations.{Message, ReadReceipt, Talker}

  postgres do
    schema "conversations"
    table "conversations"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      primary? true

      accept [:short_name, :description]
    end
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :short_name, :string
    attribute :description, :string
  end

  relationships do
    has_many :messages, Message

    many_to_many :participants, Talker do
      through ReadReceipt
      source_attribute_on_join_resource :conversation_id
      destination_attribute_on_join_resource :talker_id
    end
  end
end
