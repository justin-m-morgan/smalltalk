defmodule Smalltalk.Conversations.AdminsByActorTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations

  produce(:talker)
  produce(:conversation)

  setup %{talker: original_admin} do
    %{conversation: non_admin_conversation} =
      %{}
      |> SeedFactory.init(Smalltalk.SeedFactories.Conversations)
      |> produce(:conversation)

    Conversations.join_conversation!(non_admin_conversation.id, actor: original_admin)

    %{original_admin: original_admin, non_admin_conversation: non_admin_conversation}
  end

  test "lists expected admins", context do
    admins =
      Conversations.admins_by_actor!(actor: context.original_admin)

    assert_struct_in_list(context.conversation, admins, &(&1.id == &2.conversation_id))
    refute context.original_admin.id in Enum.map(admins, & &1.conversation_id)
  end
end
