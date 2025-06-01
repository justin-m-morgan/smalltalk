defmodule Smalltalk.Conversations.GetMessagesTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations

  produce(conversation: :conversation_1)
  produce(conversation: :conversation_2)

  test "fetches all messages from a conversation", context do
    actor = context.talker

    for _ <- 1..5, conversation <- [context.conversation_1, context.conversation_2] do
      Conversations.send_message!(
        %{
          content: "Hello world",
          conversation: conversation
        },
        actor: actor
      )
    end

    for conversation <- [context.conversation_1, context.conversation_2] do
      {:ok, messages} =
        Conversations.get_messages_for_conversation(
          %{conversation_id: conversation.id},
          actor: actor
        )

      assert Enum.all?(messages, &(&1.conversation_id == conversation.id))
    end
  end
end
