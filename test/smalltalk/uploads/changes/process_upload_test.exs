defmodule Smalltalk.Uploads.Changes.ProcessUploadTest do
  use Smalltalk.DataCase, async: false
  use Patch

  alias Smalltalk.Uploads.Changes.ProcessUpload
  alias Smalltalk.Uploads.ImageFormat
  alias Smalltalk.Uploads.ImageTag

  setup_all [
    :set_logger_level_info,
    :start_s3_container
  ]

  setup [:delete_all_bucket_objects]

  setup do
    expose(ProcessUpload, upload_original!: 2, reprocess_image!: 4, type_size: 1)

    {:ok, dir} = Briefly.create(type: :directory)
    image_path = Path.join(dir, "sample_image.webp")

    Image.new!(10, 10, color: :red)
    |> Image.write!(image_path, suffix: ".webp")

    expected_s3_path =
      private(ProcessUpload.root_path_from_image_source(image_path)) <> "/original.webp"

    %{expected_s3_path: expected_s3_path, image_path: image_path}
  end

  describe "upload_original!/1 (private)" do
    test "uploads the original image to S3", context do
      refute ExAws.S3.Interface.already_exists?(
               context.starting_bucket,
               context.expected_s3_path
             )

      private(ProcessUpload.upload_original!(context.image_path, context.starting_bucket))

      assert ExAws.S3.Interface.already_exists?(
               context.starting_bucket,
               context.expected_s3_path
             )
    end
  end

  describe "reprocess_image!/4 (private)" do
    setup context do
      root_path = ProcessUpload.root_path_from_image_source(context.image_path)
      private(ProcessUpload.upload_original!(context.image_path, context.starting_bucket))
      %{root_path: root_path}
    end

    test "creates image at correct path", context do
      for size <- ImageTag.values(), extension <- ImageFormat.values(), size != :original do
        expected_s3_path = context.root_path <> "/#{size}.#{extension}"

        refute ExAws.S3.Interface.already_exists?(
                 context.starting_bucket,
                 expected_s3_path
               )

        private(
          ProcessUpload.reprocess_image!(
            context.root_path,
            context.starting_bucket,
            size,
            extension
          )
        )

        assert ExAws.S3.Interface.already_exists?(
                 context.starting_bucket,
                 expected_s3_path
               )
      end
    end

    test "file is resized correctly", context do
      for size <- ImageTag.values(), extension <- ImageFormat.values(), size != :original do
        expected_s3_path = context.root_path <> "/#{size}.#{extension}"
        expected_width = private(ProcessUpload.type_size(size))
        expected_height = expected_width

        private(
          ProcessUpload.reprocess_image!(
            context.root_path,
            context.starting_bucket,
            size,
            extension
          )
        )

        {:ok, path} = Briefly.create()

        image =
          ExAws.S3.download_file(
            context.starting_bucket,
            expected_s3_path,
            path
          )
          |> ExAws.stream!()
          |> Image.open!()

        assert Image.width(image) == expected_width
        assert Image.height(image) == expected_height
      end
    end
  end
end
