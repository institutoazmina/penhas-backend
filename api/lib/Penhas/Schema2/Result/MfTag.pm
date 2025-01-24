#<<<
use utf8;
package Penhas::Schema2::Result::MfTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("mf_tag");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mf_tag_id_seq",
  },
  "code",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "description",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "created_on",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("mf_tag_code_key", ["code"]);
__PACKAGE__->has_many(
  "cliente_tags",
  "Penhas::Schema2::Result::ClienteTag",
  { "foreign.mf_tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-07-04 21:38:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Jp38iTkpj1ffeltewaVHaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
