#<<<
use utf8;
package Penhas::Schema2::Result::BadgeInvite;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("badge_invite");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "badge_invite_id_seq",
  },
  "badge_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "created_on",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "modified_on",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "admin_user_id",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "accepted",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "accepted_on",
  { data_type => "timestamp", is_nullable => 1 },
  "accepted_ip",
  { data_type => "inet", is_nullable => 1 },
  "accepted_user_agent",
  { data_type => "varchar", is_nullable => 1, size => 2000 },
  "deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "deleted_on",
  { data_type => "timestamp", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "badge",
  "Penhas::Schema2::Result::Badge",
  { id => "badge_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2025-04-17 11:38:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WoYE2fxZNJVuVZMho3DXww


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
