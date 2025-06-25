import Config

alias Smalltalk.{Conversations, Uploads}

config :ash,
  allow_forbidden_field_for_relationships_by_default?: true,
  include_embedded_source_by_default?: false,
  show_keysets_for_all_actions?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false],
  keep_read_action_loads_when_loading?: false,
  default_actions_require_atomic?: true,
  read_action_after_action_hooks_in_order?: true,
  bulk_actions_default_to_errors?: true,
  custom_types: [
    conversation_type: Conversations.ConversationType,
    friendship_request_status: Conversations.FriendshipRequestStatus,
    image_tag: Uploads.ImageTag,
    image_format: Uploads.ImageFormat
  ]

if Mix.env() == :dev do
  config :ash, :policies, show_policy_breakdowns?: true
  config :ash, :pub_sub, debug?: true
end
