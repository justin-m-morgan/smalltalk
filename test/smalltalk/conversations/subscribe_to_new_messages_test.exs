defmodule Smalltalk.Conversations.SubscribeToNewMessagesTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations

  produce([:conversation, user: :other_user, talker: :other_talker])
  produce([:talker])

  test "notified of new messages", context do
    # Current Implementation doesn't require joining first
    conversation_topic =
      Conversations.subscribe_to_new_messages!(context.conversation.id, actor: context.talker)

    %{message: %{content: content}} = exec(context, :send_message)

    assert_receive %{
      topic: ^conversation_topic,
      event: "create",
      payload: %{data: %{content: ^content}}
    }
  end
end
