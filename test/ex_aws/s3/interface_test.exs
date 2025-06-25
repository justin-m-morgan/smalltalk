defmodule ExAws.S3.InterfaceTest do
  use Smalltalk.DataCase, async: false
  import ExUnit.CaptureLog

  alias ExAws.S3.Interface

  setup_all [
    :set_logger_level_info,
    :start_s3_container
  ]

  setup [:delete_all_bucket_objects]

  describe "create_bucket_if_doesnt_exist/0" do
    test "skips if already exists", %{starting_bucket: starting_bucket} do
      assert capture_log(fn ->
               Interface.create_bucket_if_doesnt_exist(starting_bucket)
             end) =~ "`#{starting_bucket}` bucket already exists"
    end

    test "creates new bucket if does not exist", %{starting_bucket: starting_bucket} do
      bucket_name = Ash.UUIDv7.generate()
      assert bucket_name != starting_bucket

      assert capture_log(fn ->
               Interface.create_bucket_if_doesnt_exist(bucket_name)
             end) =~ "Creating `#{bucket_name}` Bucket"
    end
  end

  describe "upload/2" do
    test "uploads a file to the specified bucket", %{starting_bucket: bucket_name} do
      image = Image.new!(10, 10, color: :red)

      assert %{location: _, key: _} =
               image
               |> Image.stream!(suffix: ".jpg", buffer_size: 5_242_880)
               |> Interface.upload!(bucket_name, "test_image.jpg")

      object = Interface.get_object!(bucket_name, "test_image.jpg")
      assert is_binary(object)
      returned_image = Image.from_binary!(object)

      {:ok, difference, _} = Image.compare(image, returned_image, metric: :rmse)

      assert difference < 0.01, "Images should be similar, difference: #{difference}"
    end
  end

  describe "already_exists?/2" do
    test "returns false if the object does not exist", %{starting_bucket: bucket_name} do
      refute Interface.already_exists?(bucket_name, "non_existent_file.jpg")
    end

    test "returns true if the object exists", %{starting_bucket: bucket_name} do
      image = Image.new!(10, 10, color: :blue)

      image
      |> Image.stream!(suffix: ".jpg", buffer_size: 5_242_880)
      |> Interface.upload!(bucket_name, "existing_file.jpg")

      assert Interface.already_exists?(bucket_name, "existing_file.jpg")
    end
  end
end
