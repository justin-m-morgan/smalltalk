defmodule Smalltalk.Conversations.SendFriendRequestTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations

  produce([:profile, user: :requester_user, talker: :requester])
  produce([:profile, user: :requested_user, talker: :requested])

  test "can send a friendship request", context do
    request =
      Conversations.send_friend_request!(%{requested_id: context.requested.id},
        actor: context.requester
      )

    assert request.requester_id == context.requester.id
    assert request.requested_id == context.requested.id
  end
end
