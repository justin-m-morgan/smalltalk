defmodule Smalltalk.Conversations.ProfilePic do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Conversations.Talker

  postgres do
    schema "conversations"
    table "profile_pics"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy]

    read :current do
      prepare build(sort: [id: :desc], limit: 1)
    end

    create :create do
      accept [:original_src]

      change relate_actor(:talker)
    end
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :original_src, :string, allow_nil?: false
  end

  relationships do
    belongs_to :talker, Talker
  end
end
