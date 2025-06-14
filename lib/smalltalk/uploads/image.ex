defmodule Smalltalk.Uploads.Image do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Uploads,
    data_layer: AshPostgres.DataLayer

  alias Smalltalk.Uploads.ImageProcessor

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

    action :image_path, :string do
      argument :root_path, :string, allow_nil?: false
      argument :type, :image_tag, allow_nil?: false
      argument :format, :image_format, default: :webp

      run fn %{arguments: arguments}, _ ->
        {:ok,
         ImageProcessor.image_path(arguments.root_path, arguments.type, ".#{arguments.format}")}
      end
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
