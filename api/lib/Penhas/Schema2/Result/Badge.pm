#<<<
use utf8;
package Penhas::Schema2::Result::Badge;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("badges");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "badges_id_seq",
  },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "image_url",
  { data_type => "varchar", is_nullable => 0, size => 1000 },
  "linked_cep_cidade",
  { data_type => "varchar", is_nullable => 1, size => 200 },
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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "cliente_tags",
  "Penhas::Schema2::Result::ClienteTag",
  { "foreign.badge_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2025-01-30 12:15:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4LroHT+lBR80v2oGND5gHQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
