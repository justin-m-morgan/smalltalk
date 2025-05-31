defmodule Smalltalk.Conversations.CreateTalkerTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations
  alias Smalltalk.Conversations.Talker

  produce(:user)
  produce(:talker)

  test "can create a talker", context do
    assert is_struct(context.talker, Talker)
  end

  test "talker belongs to the correct user", context do
    assert context.user.id == context.talker.user_id
  end

  test "can only create one talker per user", context do
    assert {:error, errors} = Conversations.create_talker(actor: context.user)

    assert errors_contain?(errors, "user_id: has already been taken")
  end
end
