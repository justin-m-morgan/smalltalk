defmodule Smalltalk.Uploads.Image do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Uploads,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Accounts

  postgres do
    schema "uploads"
    table "images"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:s3_root_path, :user_id, :type, :extension]
      upsert? true
      upsert_identity :root_path_type_extension
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :s3_root_path, :string, allow_nil?: false
    attribute :type, :image_tag
    attribute :extension, :string
  end

  relationships do
    belongs_to :user, Accounts.User
  end

  identities do
    identity :root_path_type_extension, [:s3_root_path, :type, :extension]
  end
end
