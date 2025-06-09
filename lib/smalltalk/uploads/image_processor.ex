defmodule Smalltalk.Uploads.ImageProcessor do
  use GenServer

  alias Smalltalk.Uploads

  require Logger

  @bucket_name "images"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  @impl GenServer
  def init(_) do
    region = Application.fetch_env!(:ex_aws, :region)

    ExAws.S3.put_bucket("images", region, %{acl: :public_read})
    |> ExAws.request()
    |> case do
      {:error, {:http_error, 409, _}} ->
        Logger.debug("`images` bucket already exists")
        :ok

      {:ok, _} ->
        Logger.debug("Creating `images` Bucket")
        :ok

      error ->
        Logger.error(error)
    end

    {:ok, nil}
  end

  @impl GenServer
  def handle_info({type, s3_root_path, extension, user_id}, state) do
    process_image(s3_root_path, type, type_size(type), extension)

    Uploads.create_image!(%{
      s3_root_path: s3_root_path,
      extension: extension,
      type: type,
      user_id: user_id
    })

    {:noreply, state}
  end

  defp type_size(:thumbnail), do: 300
  defp type_size(:medium), do: 800
  defp type_size(:large), do: 1600

  def process_image(root_path, path_suffix, size, extension) do
    original_path = (root_path <> "/original") |> dbg()
    new_path = root_path <> "/#{path_suffix}"

    @bucket_name
    |> ExAws.S3.get_object(original_path)
    |> ExAws.request!()
    |> dbg()
    |> Map.get(:body)
    |> Image.from_binary!()
    |> Image.thumbnail!(size)
    |> Image.stream!(suffix: extension, buffer_size: 5_242_880)
    |> ExAws.S3.upload(@bucket_name, new_path)
    |> ExAws.request()
  end

  def submit_image(pid \\ __MODULE__, path, entry) do
    GenServer.call(pid, {:submit_image, path, entry})
  end

  def upload_original_image(pid \\ __MODULE__, path, user_id) do
    s3_root_path = hash_file(path)

    # Already upserting so no "problem" but wasted work if repeated
    already_exists? =
      Uploads.get_image_by_path!(s3_root_path, :original, ".webp",
        authorize?: false,
        not_found_error?: false
      )

    unless already_exists? do
      s3_path = "#{s3_root_path}/original"

      extension = ".webp"

      %{body: %{location: _s3_path}} =
        path
        |> Image.open!()
        |> Image.stream!(suffix: extension, buffer_size: 5_242_880)
        |> ExAws.S3.upload(@bucket_name, s3_path)
        |> ExAws.request!()

      Uploads.create_image!(%{
        s3_root_path: s3_root_path,
        extension: extension,
        type: :original,
        user_id: user_id
      })

      for resize <- [:thumbnail, :medium, :large] do
        send(pid, {resize, s3_root_path, extension, user_id})
      end
    end

    s3_root_path
  end

  defp hash_file(path) do
    hash_ref = :crypto.hash_init(:sha256)

    path
    |> File.stream!(2_048)
    |> Enum.reduce(hash_ref, &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end

  def image_path(root_path, type, _format \\ ".webp") do
    s3_config = Application.fetch_env!(:ex_aws, :s3)

    Path.join([
      "#{s3_config[:scheme]}#{s3_config[:host]}:#{s3_config[:port]}",
      @bucket_name,
      root_path,
      Atom.to_string(type)
    ])
  end
end
