#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoioSugestoesV2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio_sugestoes_v2");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ponto_apoio_sugestoes_v2_id_seq",
  },
  "cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status",
  {
    data_type     => "text",
    default_value => "awaiting-moderation",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "updated_by_admin_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_ponto_apoio_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "nome",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "categoria",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "nome_logradouro",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "cep",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "abrangencia",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "complemento",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "numero",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "bairro",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "municipio",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "uf",
  { data_type => "varchar", is_nullable => 0, size => 2 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "horario",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ddd1",
  { data_type => "integer", is_nullable => 1 },
  "telefone1",
  { data_type => "bigint", is_nullable => 1 },
  "ddd2",
  { data_type => "integer", is_nullable => 1 },
  "telefone2",
  { data_type => "bigint", is_nullable => 1 },
  "eh_24h",
  { data_type => "boolean", is_nullable => 1 },
  "has_whatsapp",
  { data_type => "boolean", is_nullable => 1 },
  "observacao",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "metainfo",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
  "saved_form",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "categoria",
  "Penhas::Schema2::Result::PontoApoioCategoria",
  { id => "categoria" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "created_ponto_apoio",
  "Penhas::Schema2::Result::PontoApoio",
  { id => "created_ponto_apoio_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-06-02 23:47:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uJ7b876wNb7Y98InxU5yoA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
