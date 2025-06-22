defmodule Smalltalk.Conversations.UnfriendTest do
  use Smalltalk.DataCase
  use SeedFactory.Test, schema: Smalltalk.SeedFactories.Conversations

  alias Smalltalk.Conversations

  produce([:profile, user: :requester_user, talker: :requester])
  produce([:profile, user: :requested_user, talker: :requested])

  describe "(pending friend request)" do
    setup context do
      request =
        %{requested_id: context.requested.id}
        |> Conversations.send_friend_request!(actor: context.requester)

      assert request.status == :pending

      %{friendship_request: request}
    end

    test "cannot unfriend", context do
      assert_raise(fn ->
        Conversations.unfriend!(context.friendship_request,
          actor: context.requester
        )
      end)
    end
  end

  describe "(rejected friend request)" do
    setup context do
      request =
        %{requested_id: context.requested.id}
        |> Conversations.send_friend_request!(actor: context.requester)
        |> Conversations.reject_friend_request!(actor: context.requested)

      assert request.status == :rejected

      %{friendship_request: request}
    end

    test "cannot unfriend", context do
      assert_raise(fn ->
        Conversations.unfriend!(context.friendship_request,
          actor: context.requester
        )
      end)
    end
  end

  describe "(accepted friend request)" do
    setup context do
      request =
        %{requested_id: context.requested.id}
        |> Conversations.send_friend_request!(actor: context.requester)
        |> Conversations.accept_friend_request!(actor: context.requested)

      assert request.status == :accepted

      %{friendship_request: request}
    end

    test "can unfriend as original requester", context do
      :ok =
        Conversations.unfriend!(context.friendship_request,
          actor: context.requester
        )

      request = Ash.reload!(context.friendship_request, authorize?: false)

      assert request.status == :unfriended
      assert request.unfriended_by_id == context.requester.id
      assert is_struct(request.unfriended_at, DateTime)
    end

    test "can unfriend as original requested", context do
      :ok =
        Conversations.unfriend!(context.friendship_request,
          actor: context.requested
        )

      request = Ash.reload!(context.friendship_request, authorize?: false)

      assert request.status == :unfriended
      assert request.unfriended_by_id == context.requested.id
      assert is_struct(request.unfriended_at, DateTime)
    end
  end
end
