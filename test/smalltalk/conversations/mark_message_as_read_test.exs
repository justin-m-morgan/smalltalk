defmodule Smalltalk.Conversations.MarkConversationAsReadTest do
  use Smalltalk.DataCase

  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations
  alias Smalltalk.Conversations.ReadReceipt

  produce(:talker)
  produce(:conversation)
  produce(:message)

  test "can mark a given message as read", context do
    actor = context.talker

    args =
      %{message: context.message}

    read_receipt = Conversations.mark_message_as_read!(args, actor: actor)

    assert is_struct(read_receipt, ReadReceipt)
    assert read_receipt.talker_id == actor.id
    assert read_receipt.most_recent_message_id == context.message.id
  end
end
