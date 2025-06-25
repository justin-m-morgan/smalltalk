defmodule Smalltalk.Uploads.Jobs.ProcessUpload do
  use Oban.Worker, queue: :image_processing, max_attempts: 3

  alias Smalltalk.Uploads

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "s3_root_path" => _path,
            "user_id" => _user_id,
            "type" => _type,
            "extension" => _extension
          } = args
      }) do
    {:ok, Uploads.reprocess_image!(args)}
  end
end
