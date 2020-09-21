#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoioProjeto;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio_projeto");
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
  "owner",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "label",
  { data_type => "varchar", is_nullable => 0, size => 200 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "ponto_apoio2projetos",
  "Penhas::Schema2::Result::PontoApoio2projeto",
  { "foreign.ponto_apoio_projeto_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-21 19:23:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k+2W4ZJn/sg5E6utIFSrvg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
