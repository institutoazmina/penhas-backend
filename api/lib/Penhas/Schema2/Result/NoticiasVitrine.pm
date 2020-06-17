#<<<
use utf8;
package Penhas::Schema2::Result::NoticiasVitrine;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("noticias_vitrine");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "prod",
    is_nullable => 0,
    size => 20,
  },
  "noticias",
  { data_type => "text", default_value => "'[]'", is_nullable => 0 },
  "order",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "meta",
  { data_type => "text", default_value => "'{}'", is_nullable => 0 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-16 20:48:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BW/j0ZgYewUWmk9O/EnXHw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
