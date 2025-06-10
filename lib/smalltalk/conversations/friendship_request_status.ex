defmodule Smalltalk.Conversations.FriendshipRequestStatus do
  use Ash.Type.Enum, values: [:pending, :rejected, :accepted, :unfriended, :canceled]
end
