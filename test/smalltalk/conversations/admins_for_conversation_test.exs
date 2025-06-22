defmodule Smalltalk.Conversations.AdminsForConversationTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations

  produce(:talker)
  produce(:conversation)

  setup %{conversation: conversation, talker: original_admin_talker} do
    [second_admin_talker, non_admin_talker] =
      for _i <- 1..2 do
        %{talker: talker} =
          %{}
          |> SeedFactory.init(Smalltalk.SeedFactories.Conversations)
          |> produce(:talker)

        Conversations.join_conversation!(conversation.id, actor: talker)
        talker
      end

    Conversations.assign_admin!(conversation, %{admins: %{talker: second_admin_talker}},
      actor: original_admin_talker
    )

    %{
      original_admin_talker: original_admin_talker,
      second_admin_talker: second_admin_talker,
      non_admin_talker: non_admin_talker
    }
  end

  test "lists expected admins", context do
    admin_talkers =
      Conversations.admins_for_conversation!(context.conversation.id,
        actor: context.original_admin_talker
      )

    assert_lists_equal(
      admin_talkers,
      [context.original_admin_talker, context.second_admin_talker],
      &(&1.talker_id == &2.id)
    )
  end
end
