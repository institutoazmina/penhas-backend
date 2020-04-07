#<<<
use utf8;
package Penhas::Schema::Result::OauthAccessToken;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("oauth_access_tokens");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "oauth_access_tokens_id_seq",
  },
  "token",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "refresh_token",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "expires_in",
  { data_type => "integer", is_nullable => 1 },
  "revoked_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 0 },
  "scopes",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "application_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "resource_owner_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  "index_oauth_access_tokens_on_refresh_token",
  ["refresh_token"],
);
__PACKAGE__->add_unique_constraint("index_oauth_access_tokens_on_token", ["token"]);
__PACKAGE__->belongs_to(
  "application",
  "Penhas::Schema::Result::OauthApplication",
  { id => "application_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->belongs_to(
  "resource_owner",
  "Penhas::Schema::Result::User",
  { id => "resource_owner_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->has_many(
  "session_activations",
  "Penhas::Schema::Result::SessionActivation",
  { "foreign.access_token_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "web_push_subscriptions",
  "Penhas::Schema::Result::WebPushSubscription",
  { "foreign.access_token_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-04-07 18:34:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wofIwPQ64LdQ3mVQwsYnnQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
