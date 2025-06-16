defmodule Smalltalk.Conversations.ConversationType do
  use Ash.Type.Enum,
    values: [
      public: "Publicly visible and joinable without approval",
      private: "Publicly visible but requires approval to join",
      secret: "Not publicly visible, only accessible by invite"
    ]
end
