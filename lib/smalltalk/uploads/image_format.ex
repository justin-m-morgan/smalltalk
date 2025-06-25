defmodule Smalltalk.Uploads.ImageFormat do
  use Ash.Type.Enum, values: [:webp]

  def match("." <> format), do: {:ok, format}
  def match(value), do: super(value)
end
