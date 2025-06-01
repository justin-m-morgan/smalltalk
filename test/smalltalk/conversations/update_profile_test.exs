defmodule Smalltalk.Conversations.UpdateProfileTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations

  produce(:talker)
  produce(:profile)

  test "can update profile details", context do
    actor = context.talker

    updates = %{
      nickname: "NewNickname"
    }

    assert {:ok, updated_profile} =
             Conversations.update_profile(context.profile, updates, actor: actor)

    assert_maps_equal(updated_profile, updates, [:nickname])
    assert_maps_equal(updated_profile, context.profile, [:first_name, :last_name])
  end
end
