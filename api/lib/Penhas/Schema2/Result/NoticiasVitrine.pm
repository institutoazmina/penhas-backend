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
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "noticias_vitrine_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "prod",
    is_nullable => 0,
    size => 20,
  },
  "noticias",
  { data_type => "text", default_value => "[]", is_nullable => 0 },
  "order",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "meta",
  { data_type => "text", default_value => "{}", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0xGzUALzaVtkG/7396qqHg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
