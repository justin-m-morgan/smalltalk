defmodule Smalltalk.Conversations.AssignAdminTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations

  produce(:talker)
  produce(:conversation)

  test "can assign admin if already admin", context do
    %{talker: new_admin} =
      %{}
      |> SeedFactory.init(Smalltalk.SeedFactories.Conversations)
      |> produce(:talker)

    conversation =
      Conversations.assign_admin!(context.conversation, %{admins: %{talker: new_admin}},
        actor: context.talker
      )

    assert_struct_in_list(new_admin, conversation.admins, &(&1.id == &2.talker_id))
  end

  test "cannot assign admin if not already admin", context do
    [talker_1, talker_2] =
      for _i <- 1..2 do
        %{talker: talker} =
          %{}
          |> SeedFactory.init(Smalltalk.SeedFactories.Conversations)
          |> produce(:talker)

        Conversations.join_conversation!(context.conversation.id, actor: talker)
        talker
      end

    assert_raise(Ash.Error.Forbidden, fn ->
      Conversations.assign_admin!(context.conversation, %{admins: %{talker: talker_2}},
        actor: talker_1
      )
    end)
  end
end
