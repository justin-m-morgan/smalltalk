defmodule Smalltalk.Uploads.CreateImageTest do
  use Smalltalk.DataCase, async: false
  use Patch
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Accounts

  alias Smalltalk.Uploads
  alias Smalltalk.Uploads.Changes.ProcessUpload

  describe "create_image -" do
    produce(:user)

    setup do
      fake_file_path = "fake/path/to/image.webp"
      fake_s3_root_path = Ash.UUIDv7.generate()
      fake_s3_path = fake_s3_root_path <> "/original.webp"

      expose(ProcessUpload, upload_original!: 2, reprocess_image!: 4)

      %{
        fake_file_path: fake_file_path,
        fake_s3_path: fake_s3_path,
        fake_s3_root_path: fake_s3_root_path
      }
    end

    test "uploads original image if file_path is provided", context do
      patch(ProcessUpload, :upload_original!, context.fake_s3_root_path)

      upload =
        Uploads.create_image!(%{file_path: context.fake_file_path}, actor: context.user)

      assert upload.s3_root_path == context.fake_s3_root_path
      assert upload.type == :original
      assert upload.extension == :webp
      assert upload.user_id == context.user.id
    end

    test "calls correct side effects", context do
      expected_root_path = context.fake_s3_root_path
      expected_file_path = context.fake_file_path
      expected_user_id = context.user.id
      patch(ProcessUpload, :upload_original!, context.fake_s3_root_path)

      Uploads.create_image!(%{file_path: context.fake_file_path}, actor: context.user)

      assert_called(ProcessUpload.upload_original!(^expected_file_path, "images"))

      assert_called(
        ProcessUpload.kickoff_variation_processing_jobs(^expected_root_path, ^expected_user_id)
      )

      refute_any_call(ProcessUpload, :reprocess_image!)
    end
  end
end
