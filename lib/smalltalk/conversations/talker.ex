defmodule Smalltalk.Conversations.Talker do
  use Ash.Resource,
    otp_app: :smalltalk,
    domain: Smalltalk.Conversations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Smalltalk.Conversations.{
    Admin,
    Conversation,
    FriendshipRequest,
    Profile,
    ProfilePic,
    Participant,
    ReadReceipt,
    Talker
  }

  postgres do
    schema "conversations"
    table "talkers"
    repo Smalltalk.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    read :me

    read :friend do
      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end

      filter expr(
               (id != ^actor(:id) &&
                  (inbound_friendship_requests.status == :accepted and
                     inbound_friendship_requests.requested_id == ^actor(:id))) ||
                 (outbound_friendship_requests.status == :accepted and
                    outbound_friendship_requests.requester_id == ^actor(:id))
             )
    end

    create :create do
      primary? true
      argument :profile, :map, default: %{}

      change relate_actor(:user)
    end

    update :current_profile_pic do
      accept [:current_profile_pic_id]
    end
  end

  policies do
    policy action(:me) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:update) do
      authorize_if expr(^actor(:id) == id)
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end
  end

  attributes do
    uuid_v7_primary_key :id
  end

  relationships do
    belongs_to :user, Smalltalk.Accounts.User
    has_one :profile, Profile
    has_many :profile_pics, ProfilePic
    belongs_to :current_profile_pic, ProfilePic

    has_many :read_receipts, ReadReceipt

    many_to_many :conversations, Conversation do
      through Participant
      source_attribute_on_join_resource :talker_id
      destination_attribute_on_join_resource :conversation_id
    end

    has_many :inbound_friendship_requests, FriendshipRequest do
      destination_attribute :requester_id
    end

    has_many :outbound_friendship_requests, FriendshipRequest do
      destination_attribute :requested_id
    end

    has_many :friends, Talker do
      read_action :is_friend
      destination_attribute :id
    end

    has_many :admins, Admin
  end

  calculations do
    calculate :email, :string, expr(user.email), public?: true

    calculate :full_name, :string, expr(profile.first_name <> " " <> profile.last_name),
      public?: true

    calculate :current_profile_pic_source, :string, expr(current_profile_pic.original_src)

    calculate :is_admin?, :boolean, expr(admins.conversation_id == args(:conversation_id)) do
      argument :conversation_id, :uuid_v7 do
        allow_nil? false
      end
    end
  end

  identities do
    identity :unique_user, [:user_id]
  end
end
