defmodule ExAws.S3.Interface do
  require Logger

  def create_bucket_if_doesnt_exist(bucket_name) do
    region = Application.fetch_env!(:ex_aws, :region)

    ExAws.S3.put_bucket(bucket_name, region, %{acl: :public_read})
    |> ExAws.request()
    |> case do
      {:error, {:http_error, 409, _}} ->
        Logger.info("`#{bucket_name}` bucket already exists")
        :ok

      {:ok, _} ->
        Logger.info("Creating `#{bucket_name}` Bucket")
        :ok

      error ->
        Logger.error(error)
        :error
    end
  end

  def upload!(source, bucket_name, path) do
    source
    |> ExAws.S3.upload(bucket_name, path)
    |> ExAws.request!()
    |> Map.get(:body)
  end

  def get_object!(bucket, path) do
    bucket
    |> ExAws.S3.get_object(path)
    |> ExAws.request!()
    |> Map.get(:body)
  end

  def already_exists?(bucket, path) do
    ExAws.S3.head_object(bucket, path)
    |> ExAws.request()
    |> case do
      {:ok, %{status_code: 200}} -> true
      {:error, {_, 404, _}} -> false
    end
  end
end
