defmodule Smalltalk.Conversations.SendMessageTest do
  use Smalltalk.DataCase

  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations.{Message}

  produce(:talker)
  produce(:conversation)
  produce(:message)

  test "can send a message to a valid conversation", context do
    assert is_struct(context.message, Message)
    assert is_bitstring(context.message.content)
  end
end
