defmodule Smalltalk.Uploads.Changes.ProcessUpload do
  use Ash.Resource.Change

  alias ExAws.S3
  alias Smalltalk.Uploads

  @impl true
  def init(opts) do
    Keyword.fetch!(opts, :bucket_name)
    {:ok, opts}
  end

  @impl true
  def change(changeset, opts, context) do
    bucket_name = Keyword.fetch!(opts, :bucket_name)

    changeset
    |> Ash.Changeset.before_transaction(fn changeset ->
      S3.Interface.create_bucket_if_doesnt_exist(bucket_name)

      case Ash.Changeset.get_argument(changeset, :file_path) do
        path when is_binary(path) ->
          root_path = upload_original!(path, bucket_name)
          kickoff_variation_processing_jobs(root_path, context.actor.id)

          Ash.Changeset.force_change_attribute(changeset, :s3_root_path, root_path)

        nil ->
          root_path = Ash.Changeset.get_attribute(changeset, :s3_root_path)
          type = Ash.Changeset.get_attribute(changeset, :type)
          extension = Ash.Changeset.get_attribute(changeset, :extension)

          reprocess_image!(root_path, bucket_name, type, extension)

          changeset
      end
    end)
  end

  defp upload_original!(file_path, bucket) do
    s3_root_path = root_path_from_image_source(file_path)
    extension = ".webp"
    s3_path = "#{s3_root_path}/original#{extension}"

    unless S3.Interface.already_exists?(bucket, s3_path) do
      file_path
      |> Image.open!()
      |> Image.stream!(suffix: extension, buffer_size: 5_242_880)
      |> S3.Interface.upload!(bucket, s3_path)
    end

    s3_root_path
  end

  defp reprocess_image!(root_path, bucket, size, extension) do
    original_path = root_path <> "/original.#{extension}"
    new_path = root_path <> "/#{size}.#{extension}"

    bucket
    |> ExAws.S3.download_file(original_path, :memory)
    |> ExAws.stream!()
    |> Image.open!()
    |> Image.thumbnail!(type_size(size))
    |> Image.stream!(suffix: ".#{extension}", buffer_size: 5_242_880)
    |> S3.Interface.upload!(bucket, new_path)
  end

  defp type_size(:thumbnail), do: 300
  defp type_size(:medium), do: 800
  defp type_size(:large), do: 1600

  defp kickoff_variation_processing_jobs(root_path, actor_id) do
    for type <- Uploads.ImageTag.values(),
        extension <- Uploads.ImageFormat.values(),
        type != :original do
      %{
        "s3_root_path" => root_path,
        "user_id" => actor_id,
        "type" => type,
        "extension" => extension
      }
      |> Smalltalk.Uploads.Jobs.ProcessUpload.new()
    end
    |> Oban.insert_all()
  end

  def root_path_from_image_source(path) do
    hash_ref = :crypto.hash_init(:sha256)

    path
    |> File.stream!(2_048)
    |> Enum.reduce(hash_ref, &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end
end
