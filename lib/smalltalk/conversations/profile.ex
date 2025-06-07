defmodule Smalltalk.Conversations.Profile do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Conversations.{Talker}

  postgres do
    schema "conversations"
    table "profiles"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, :update]

    default_accept [
      :first_name,
      :last_name,
      :nickname,
      :image_src,
      :age,
      :location,
      :relationship_status,
      :hobbies,
      :profession,
      :education
    ]

    create :create do
      primary? true
      upsert? true
      upsert_identity :unique_talker

      accept [
        :first_name,
        :last_name,
        :nickname,
        :image_src,
        :age,
        :location,
        :relationship_status,
        :hobbies,
        :profession,
        :education
      ]

      change relate_actor(:talker)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :first_name, :string, allow_nil?: false
    attribute :last_name, :string, allow_nil?: false
    attribute :nickname, :string, allow_nil?: false
    attribute :image_src, :string

    attribute :age, :integer
    attribute :location, :string
    attribute :relationship_status, :string
    attribute :hobbies, :string
    attribute :profession, :string
    attribute :education, :string

    # More for bots
    attribute :personality_traits, :string
  end

  relationships do
    belongs_to :talker, Talker
  end

  identities do
    identity :unique_talker, [:talker_id]
  end
end
