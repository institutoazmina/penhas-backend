#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoioCategoria;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio_categoria");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ponto_apoio_categoria_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "prod",
    is_nullable => 0,
    size => 20,
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "label",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "color",
  {
    data_type => "varchar",
    default_value => "#000000",
    is_nullable => 0,
    size => 7,
  },
  "owner",
  { data_type => "uuid", is_nullable => 1, size => 16 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "ponto_apoio_categoria2projetos",
  "Penhas::Schema2::Result::PontoApoioCategoria2projeto",
  { "foreign.ponto_apoio_categoria_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "ponto_apoios",
  "Penhas::Schema2::Result::PontoApoio",
  { "foreign.categoria" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-25 04:03:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BIHwEnemBiNn2v2Z21jhcQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
