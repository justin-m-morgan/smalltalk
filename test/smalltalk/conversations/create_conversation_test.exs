defmodule Smalltalk.Conversations.CreateConversationTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations.Conversation

  produce(:talker)
  produce(:conversation)

  test "can create a conversation", context do
    assert is_struct(context.conversation, Conversation)
  end

  test "can set metadata", context do
    assert is_bitstring(context.conversation.short_name)
    assert is_bitstring(context.conversation.description)
  end
end
