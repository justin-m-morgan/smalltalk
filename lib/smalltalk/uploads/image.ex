defmodule Smalltalk.Uploads.Image do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Uploads,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  alias Smalltalk.Accounts
  alias Smalltalk.Uploads.Changes.ProcessUpload

  @bucket_name "images"

  postgres do
    schema "uploads"
    table "images"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create_original do
      primary? true
      argument :file_path, :string

      upsert? true
      upsert_identity :root_path_type_extension

      change relate_actor(:user)
      change set_attribute(:type, :original)
      change set_attribute(:extension, :webp)

      change fn ch, c ->
        dbg(c.actor)
        ch
      end

      change {ProcessUpload, bucket_name: @bucket_name}
    end

    create :reprocess do
      upsert? true
      upsert_identity :root_path_type_extension
      accept [:s3_root_path, :type, :extension, :user_id]

      change {ProcessUpload, bucket_name: @bucket_name}
    end

    action :image_path, :string do
      argument :root_path, :string, allow_nil?: false
      argument :type, :image_tag, allow_nil?: false
      argument :extension, :image_format, default: :webp

      run fn %{arguments: arguments}, _ ->
        s3_config = Application.fetch_env!(:ex_aws, :s3)

        path =
          Path.join([
            "#{s3_config[:scheme]}#{s3_config[:host]}:#{s3_config[:port]}",
            @bucket_name,
            arguments.root_path,
            "#{arguments.type}.#{arguments.extension}"
          ])

        {:ok, path}
      end
    end

    action :subscribe_to_new_images_topic do
      run fn _, context ->
        Phoenix.PubSub.subscribe(
          Smalltalk.PubSub,
          "images:user:#{context.actor.id}"
        )

        :ok
      end
    end
  end

  pub_sub do
    module SmalltalkWeb.Endpoint

    publish :create_original, ["images", "user", :user_id]
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :s3_root_path, :string, allow_nil?: false
    attribute :type, :image_tag
    attribute :extension, :image_format, default: :webp
  end

  relationships do
    belongs_to :user, Accounts.User
  end

  identities do
    identity :root_path_type_extension, [:s3_root_path, :type, :extension]
  end
end
