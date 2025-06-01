defmodule Smalltalk.Conversations.Profile do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Conversations.{Talker}

  postgres do
    # schema "conversations" -- Intentionally leaving at top-level as shared
    table "profiles"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, :update]
    default_accept [:first_name, :last_name, :nickname]

    create :create do
      primary? true
      upsert? true
      upsert_identity :unique_talker

      accept [:first_name, :last_name, :nickname]
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :first_name, :string
    attribute :last_name, :string
    attribute :nickname, :string
  end

  relationships do
    belongs_to :talker, Talker
  end

  identities do
    identity :unique_talker, [:talker_id]
  end
end
