#<<<
use utf8;
package Penhas::Schema2::Result::Preference;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("preferences");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "label",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "active",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 0 },
  "initial_value",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "sort",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "clientes_preferences",
  "Penhas::Schema2::Result::ClientesPreference",
  { "foreign.preference_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-11-03 21:24:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eTPr1/mtj2GetcMOPlpCvA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
