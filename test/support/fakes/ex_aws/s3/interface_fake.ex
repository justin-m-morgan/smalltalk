defmodule ExAws.S3.InterfaceFake do
  def create_bucket_if_doesnt_exist(_bucket_name) do
    :ok
  end

  def upload!(_source, bucket_name, path) do
    %{
      location: "https://example.com/fake-uploaded-file",
      key: path,
      bucket: bucket_name
    }
  end

  def get_object!(_bucket, _path) do
    Image.new!(10, 10, color: :red) |> Image.write!(:memory)
  end

  def already_exists?(_bucket, _path) do
    false
  end
end
