#<<<
use utf8;
package Penhas::Schema2::Result::GeoCache;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("geo_cache");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "key",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "value",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "valid_until",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-10 10:20:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ro7UbLLrPySFCL8bzG85qw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
