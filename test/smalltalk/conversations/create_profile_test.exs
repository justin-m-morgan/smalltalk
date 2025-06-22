defmodule Smalltalk.Conversations.CreateProfileTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations.{Profile}

  produce(:talker)
  produce(:profile)

  test "can create a profile", context do
    assert is_struct(context.profile, Profile)
  end

  test "will upsert if profile already exists", context do
    updates = %{
      first_name: "NewFirstName",
      last_name: "NewLastName",
      nickname: "NewNickName"
    }

    assert {:ok, profile} = Smalltalk.Conversations.create_profile(updates, actor: context.talker)
    assert profile.id == context.profile.id
    assert_maps_equal(profile, updates, [:first_name, :last_name, :nickname])
  end
end
