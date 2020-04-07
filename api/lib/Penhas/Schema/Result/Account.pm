#<<<
use utf8;
package Penhas::Schema::Result::Account;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("accounts");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "accounts_id_seq",
  },
  "username",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "domain",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "secret",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "private_key",
  { data_type => "text", is_nullable => 1 },
  "public_key",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "remote_url",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "salmon_url",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "hub_url",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 0 },
  "note",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "display_name",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "uri",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "url",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "avatar_file_name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "avatar_content_type",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "avatar_file_size",
  { data_type => "integer", is_nullable => 1 },
  "avatar_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "header_file_name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "header_content_type",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "header_file_size",
  { data_type => "integer", is_nullable => 1 },
  "header_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "avatar_remote_url",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "subscription_expires_at",
  { data_type => "timestamp", is_nullable => 1 },
  "locked",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "header_remote_url",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "last_webfingered_at",
  { data_type => "timestamp", is_nullable => 1 },
  "inbox_url",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "outbox_url",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "shared_inbox_url",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "followers_url",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "protocol",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "memorial",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "moved_to_account_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "featured_collection_url",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "fields",
  { data_type => "jsonb", is_nullable => 1 },
  "actor_type",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "discoverable",
  { data_type => "boolean", is_nullable => 1 },
  "also_known_as",
  { data_type => "character varying[]", is_nullable => 1 },
  "silenced_at",
  { data_type => "timestamp", is_nullable => 1 },
  "suspended_at",
  { data_type => "timestamp", is_nullable => 1 },
  "trust_level",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "account_aliases",
  "Penhas::Schema::Result::AccountAlias",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_conversations",
  "Penhas::Schema::Result::AccountConversation",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_domain_blocks",
  "Penhas::Schema::Result::AccountDomainBlock",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_identity_proofs",
  "Penhas::Schema::Result::AccountIdentityProof",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_migrations_accounts",
  "Penhas::Schema::Result::AccountMigration",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_migrations_target_accounts",
  "Penhas::Schema::Result::AccountMigration",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_moderation_notes_accounts",
  "Penhas::Schema::Result::AccountModerationNote",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_moderation_notes_target_accounts",
  "Penhas::Schema::Result::AccountModerationNote",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_pins_accounts",
  "Penhas::Schema::Result::AccountPin",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_pins_target_accounts",
  "Penhas::Schema::Result::AccountPin",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->might_have(
  "account_stat",
  "Penhas::Schema::Result::AccountStat",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_warnings_accounts",
  "Penhas::Schema::Result::AccountWarning",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "account_warnings_target_accounts",
  "Penhas::Schema::Result::AccountWarning",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "accounts",
  "Penhas::Schema::Result::Account",
  { "foreign.moved_to_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "admin_action_logs",
  "Penhas::Schema::Result::AdminActionLog",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "blocks_accounts",
  "Penhas::Schema::Result::Block",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "blocks_target_accounts",
  "Penhas::Schema::Result::Block",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "conversation_mutes",
  "Penhas::Schema::Result::ConversationMute",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "custom_filters",
  "Penhas::Schema::Result::CustomFilter",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "favourites",
  "Penhas::Schema::Result::Favourite",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "featured_tags",
  "Penhas::Schema::Result::FeaturedTag",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "follow_requests_accounts",
  "Penhas::Schema::Result::FollowRequest",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "follow_requests_target_accounts",
  "Penhas::Schema::Result::FollowRequest",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "follows_accounts",
  "Penhas::Schema::Result::Follow",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "follows_target_accounts",
  "Penhas::Schema::Result::Follow",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "imports",
  "Penhas::Schema::Result::Import",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "list_accounts",
  "Penhas::Schema::Result::ListAccount",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "lists",
  "Penhas::Schema::Result::List",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "media_attachments",
  "Penhas::Schema::Result::MediaAttachment",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "mentions",
  "Penhas::Schema::Result::Mention",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "moved_to_account",
  "Penhas::Schema::Result::Account",
  { id => "moved_to_account_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->has_many(
  "mutes_accounts",
  "Penhas::Schema::Result::Mute",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "mutes_target_accounts",
  "Penhas::Schema::Result::Mute",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "notifications_accounts",
  "Penhas::Schema::Result::Notification",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "notifications_from_account",
  "Penhas::Schema::Result::Notification",
  { "foreign.from_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "poll_votes",
  "Penhas::Schema::Result::PollVote",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "polls",
  "Penhas::Schema::Result::Poll",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "report_notes",
  "Penhas::Schema::Result::ReportNote",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "reports_accounts",
  "Penhas::Schema::Result::Report",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "reports_actions_taken_by_account",
  "Penhas::Schema::Result::Report",
  { "foreign.action_taken_by_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "reports_assigned_accounts",
  "Penhas::Schema::Result::Report",
  { "foreign.assigned_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "reports_target_accounts",
  "Penhas::Schema::Result::Report",
  { "foreign.target_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "scheduled_statuses",
  "Penhas::Schema::Result::ScheduledStatus",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "status_pins",
  "Penhas::Schema::Result::StatusPin",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "statuses_accounts",
  "Penhas::Schema::Result::Status",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "statuses_in_reply_to_account",
  "Penhas::Schema::Result::Status",
  { "foreign.in_reply_to_account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tombstones",
  "Penhas::Schema::Result::Tombstone",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "users",
  "Penhas::Schema::Result::User",
  { "foreign.account_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-04-07 18:34:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N62JfZI1a4LanHt3xxSlSQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
