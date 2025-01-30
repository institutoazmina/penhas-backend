#<<<
use utf8;
package Penhas::Schema2::Result::ClienteTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("cliente_tag");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cliente_tag_id_seq",
  },
  "cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mf_tag_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_on",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "badge_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "valid_until",
  { data_type => "timestamp", default_value => "infinity", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("unique_cliente_tag", ["cliente_id", "mf_tag_id"]);
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
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "mf_tag",
  "Penhas::Schema2::Result::MfTag",
  { id => "mf_tag_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2025-01-30 12:15:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CvoM4Rfae3lYNJAY6szobw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
