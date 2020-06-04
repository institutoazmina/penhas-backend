#<<<
use utf8;
package Penhas::Schema2::Result::Noticias2tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("noticias2tags");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "noticias_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "tag_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-03 07:00:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zEttD1MLzm7b3NMT3cP4/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
