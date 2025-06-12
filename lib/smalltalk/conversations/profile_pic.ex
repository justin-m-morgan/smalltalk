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

      change after_action(fn _changeset, profile_pic, context ->
               actor = context.actor

               Ash.update!(actor, %{current_profile_pic_id: profile_pic.id},
                 actor: actor,
                 action: :current_profile_pic
               )

               {:ok, profile_pic}
             end)
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
