#<<<
use utf8;
package Penhas::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "users_id_seq",
  },
  "email",
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
  "encrypted_password",
  {
    data_type     => "text",
    default_value => "",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "reset_password_token",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "reset_password_sent_at",
  { data_type => "timestamp", is_nullable => 1 },
  "remember_created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "sign_in_count",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "current_sign_in_at",
  { data_type => "timestamp", is_nullable => 1 },
  "last_sign_in_at",
  { data_type => "timestamp", is_nullable => 1 },
  "current_sign_in_ip",
  { data_type => "inet", is_nullable => 1 },
  "last_sign_in_ip",
  { data_type => "inet", is_nullable => 1 },
  "admin",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "confirmation_token",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "confirmed_at",
  { data_type => "timestamp", is_nullable => 1 },
  "confirmation_sent_at",
  { data_type => "timestamp", is_nullable => 1 },
  "unconfirmed_email",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "locale",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "encrypted_otp_secret",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "encrypted_otp_secret_iv",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "encrypted_otp_secret_salt",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "consumed_timestep",
  { data_type => "integer", is_nullable => 1 },
  "otp_required_for_login",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "last_emailed_at",
  { data_type => "timestamp", is_nullable => 1 },
  "otp_backup_codes",
  { data_type => "character varying[]", is_nullable => 1 },
  "filtered_languages",
  {
    data_type     => "character varying[]",
    default_value => \"'{}'::character varying[]",
    is_nullable   => 0,
  },
  "account_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "disabled",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "moderator",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "invite_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "remember_token",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "chosen_languages",
  { data_type => "character varying[]", is_nullable => 1 },
  "created_by_application_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "approved",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("index_users_on_confirmation_token", ["confirmation_token"]);
__PACKAGE__->add_unique_constraint("index_users_on_email", ["email"]);
__PACKAGE__->add_unique_constraint("index_users_on_remember_token", ["remember_token"]);
__PACKAGE__->add_unique_constraint(
  "index_users_on_reset_password_token",
  ["reset_password_token"],
);
__PACKAGE__->belongs_to(
  "account",
  "Penhas::Schema::Result::Account",
  { id => "account_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);
__PACKAGE__->has_many(
  "backups",
  "Penhas::Schema::Result::Backup",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "created_by_application",
  "Penhas::Schema::Result::OauthApplication",
  { id => "created_by_application_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->has_many(
  "identities",
  "Penhas::Schema::Result::Identity",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "invite",
  "Penhas::Schema::Result::Invite",
  { id => "invite_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->has_many(
  "invites",
  "Penhas::Schema::Result::Invite",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "markers",
  "Penhas::Schema::Result::Marker",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "oauth_access_grants",
  "Penhas::Schema::Result::OauthAccessGrant",
  { "foreign.resource_owner_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "oauth_access_tokens",
  "Penhas::Schema::Result::OauthAccessToken",
  { "foreign.resource_owner_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "oauth_applications",
  "Penhas::Schema::Result::OauthApplication",
  { "foreign.owner_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "session_activations",
  "Penhas::Schema::Result::SessionActivation",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "user_invite_requests",
  "Penhas::Schema::Result::UserInviteRequest",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "web_push_subscriptions",
  "Penhas::Schema::Result::WebPushSubscription",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->might_have(
  "web_setting",
  "Penhas::Schema::Result::WebSetting",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-04-07 18:34:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oUPwJATNGqj/x6JP15YRbA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
