defmodule Smalltalk.Uploads.ReprocessImageTest do
  use Smalltalk.DataCase, async: false
  use Patch
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Accounts

  alias Smalltalk.Uploads
  alias Smalltalk.Uploads.Changes.ProcessUpload

  describe "create_image -" do
    produce(:user)

    setup do
      fake_s3_root_path = Ash.UUIDv7.generate()

      expose(ProcessUpload, upload_original!: 2, reprocess_image!: 4)

      %{
        fake_s3_root_path: fake_s3_root_path
      }
    end

    test "creates image", context do
      patch(ProcessUpload, :reprocess_image!, :ok)

      for type <- Uploads.ImageTag.values(),
          extension <- Uploads.ImageFormat.values(),
          type != :original do
        upload =
          Uploads.reprocess_image!(
            %{s3_root_path: context.fake_s3_root_path, type: type, extension: extension},
            actor: context.user
          )

        assert upload.s3_root_path == context.fake_s3_root_path
        assert upload.type == type
        assert upload.extension == extension
        assert upload.user_id == context.user.id
      end
    end

    test "calls correct side effects", context do
      patch(ProcessUpload, :reprocess_image!, :ok)

      for type <- Uploads.ImageTag.values(),
          extension <- Uploads.ImageFormat.values(),
          type != :original do
        expected_root_path = context.fake_s3_root_path

        Uploads.reprocess_image!(
          %{s3_root_path: context.fake_s3_root_path, type: type, extension: extension},
          actor: context.user
        )

        refute_any_call(ProcessUpload, :upload_original!)
        refute_any_call(ProcessUpload, :kickoff_variation_processing_jobs)

        assert_called(
          ProcessUpload.reprocess_image!(
            ^expected_root_path,
            "images",
            ^type,
            ^extension
          )
        )
      end
    end
  end
end
