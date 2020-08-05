#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoioSugestoe;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio_sugestoes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "endereco_ou_cep",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "nome",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "categoria",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "descricao_servico",
  { data_type => "text", is_nullable => 0 },
  "cliente_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "metainfo",
  { data_type => "text", default_value => "'{}'", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-05 19:29:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ARekuVyh4I2ge3/FlwdcbQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
