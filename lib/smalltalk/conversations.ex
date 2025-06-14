defmodule Smalltalk.Conversations do
  use Ash.Domain,
    otp_app: :smalltalk,
    extensions: [AshPhoenix]

  resources do
    resource Smalltalk.Conversations.Talker do
      define :create_talker, action: :create
      define :get_talker, action: :read, get?: true
      define :get_talker_by_id, action: :read, get_by: :id
      define :get_me, action: :me, get?: true
      define :all_talkers, action: :read
      define :all_friends, action: :friend
      define :set_current_profile_pic, action: :current_profile_pic
    end

    resource Smalltalk.Conversations.Conversation do
      define :create_conversation, action: :create
      define :get_conversations, action: :read
      define :get_conversation, action: :read, get_by: :id
      define :get_my_conversations, action: :mine
    end

    resource Smalltalk.Conversations.Profile do
      define :get_profile, action: :read, get?: true
      define :update_profile, action: :update
      define :create_profile, action: :create
    end

    resource Smalltalk.Conversations.Message do
      define :send_message, action: :create

      define :get_messages_for_conversation,
        action: :read_by_conversation_id

      define :subscribe_to_new_messages, args: [:conversation_id]
    end

    resource Smalltalk.Conversations.ReadReceipt do
      define :mark_message_as_read, action: :mark_as_read
    end

    resource Smalltalk.Conversations.Participants do
      define :join_conversation, action: :join, args: [:conversation_id]
      define :leave_conversation, action: :leave, args: [:conversation_id]
      define :update_last_active, action: :last_active
      define :participants, action: :read

      define :participants_not_present,
        action: :excluding_presence,
        args: [:conversation_id, :presence_ids]
    end

    resource Smalltalk.Conversations.ProfilePic do
      define :submit_profile_pic, action: :create
    end

    resource Smalltalk.Conversations.FriendshipRequest do
      define :send_friend_request, action: :create
      define :all_requests, action: :read
      define :inbound_friend_requests, action: :inbound
      define :outbound_friend_requests, action: :outbound
      define :accept_friend_request, action: :accept
      define :reject_friend_request, action: :reject
      define :cancel_friend_request, action: :cancel
      define :revive_friend_request, action: :cancel
      define :get_friend_request, action: :by_talker_id, args: [:talker_id], get?: true
      define :unfriend
    end
  end
end
