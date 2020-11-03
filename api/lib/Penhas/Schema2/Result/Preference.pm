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
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-11-03 17:23:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UPuJsZ6/O037dYqGGQ7zdA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
