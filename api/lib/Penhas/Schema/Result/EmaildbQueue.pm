#<<<
use utf8;
package Penhas::Schema::Result::EmaildbQueue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("emaildb_queue");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"uuid_generate_v4()",
    is_nullable => 0,
    size => 16,
  },
  "config_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "template",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "to",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "subject",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "variables",
  { data_type => "json", is_nullable => 0 },
  "sent",
  { data_type => "boolean", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "visible_after",
  { data_type => "timestamp", is_nullable => 1 },
  "errmsg",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "config",
  "Penhas::Schema::Result::EmaildbConfig",
  { id => "config_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-04-11 16:28:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:meVfyN5cF3jxTb8PDCq7aA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
