defmodule Smalltalk.Conversations do
  use Ash.Domain,
    otp_app: :smalltalk,
    extensions: [AshPhoenix]

  alias Smalltalk.Conversations.{
    Talker,
    Conversation,
    Profile,
    Message,
    ReadReceipt,
    Participant,
    ProfilePic,
    FriendshipRequest,
    Admin
  }

  resources do
    resource Admin do
      define :admins_by_actor, action: :by_actor
      define :admins_for_conversation, action: :for_conversation, args: [:conversation_id]
    end

    resource Conversation do
      define :assign_admin
      define :create_conversation, action: :create
      define :get_conversation, action: :read, get_by: :id
    end

    resource FriendshipRequest do
      define :send_friend_request, action: :create
      define :accept_friend_request, action: :accept
      define :reject_friend_request, action: :reject
      define :cancel_friend_request, action: :cancel
      define :get_friend_request, action: :by_talker_id, args: [:talker_id], get?: true
      define :unfriend
    end

    resource Message do
      define :send_message, action: :create

      define :get_messages_for_conversation,
        action: :read_by_conversation_id

      define :subscribe_to_new_messages, args: [:conversation_id]
    end

    resource Participant do
      define :join_conversation, action: :join, args: [:conversation_id]
      define :leave_conversation, action: :leave, args: [:conversation_id]
      define :update_last_active, action: :last_active
      # define :participants, action: :read

      define :participants_not_present,
        action: :excluding_presence,
        args: [:conversation_id, :presence_ids]

      define :participants_blocked,
        action: :blocked,
        args: [:conversation_id]

      define :get_participant, action: :read, get_by: :id

      define :get_participant_by_actor_conversation,
        action: :read,
        get_by_identity: :unique_talker

      define :unblock_participant, action: :unblock

      # define :participants_by_actor, action: :by_actor
    end

    resource Profile do
      # define :get_profile, action: :read, get?: true
      define :update_profile, action: :update
      define :create_profile, action: :create
    end

    resource ProfilePic do
      define :submit_profile_pic, action: :create
      define :my_profile_pics, action: :read
    end

    resource ReadReceipt do
      define :mark_message_as_read, action: :mark_as_read
    end

    resource Talker do
      define :create_talker, action: :create
      define :get_me, action: :me, get?: true
      define :all_talkers, action: :read
      define :set_current_profile_pic, action: :current_profile_pic
      # define :get_talker, action: :read, get?: true
      # define :get_talker_by_id, action: :read, get_by: :id
      # define :all_friends, action: :friend
    end
  end
end
