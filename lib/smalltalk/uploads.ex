defmodule Smalltalk.Uploads do
  use Ash.Domain,
    otp_app: :smalltalk

  resources do
    resource Smalltalk.Uploads.Image do
      define :create_image, action: :create
      define :get_image_by_path, action: :read, get_by_identity: :root_path_type_extension
    end
  end
end
