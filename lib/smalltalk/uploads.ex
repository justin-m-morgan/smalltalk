defmodule Smalltalk.Uploads do
  use Ash.Domain,
    otp_app: :smalltalk

  resources do
    resource Smalltalk.Uploads.Image do
      define :create_image, action: :create_original
      define :reprocess_image, action: :reprocess
      define :get_image_by_path, action: :read, get_by_identity: :root_path_type_extension
      define :image_path, args: [:root_path, :type]
      define :subscribe_to_new_images_topic
    end
  end
end
