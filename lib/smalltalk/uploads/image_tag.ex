defmodule Smalltalk.Uploads.ImageTag do
  use Ash.Type.Enum, values: [:thumbnail, :original, :medium, :large]
end
