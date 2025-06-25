defmodule Smalltalk.Uploads.ImageProcessorTest do
  use Smalltalk.DataCase, async: false

  use Patch

  setup do
    fake(ExAws.S3.Interface, Smalltalk.Uploads.ImageProcessorFake)
  end
end
