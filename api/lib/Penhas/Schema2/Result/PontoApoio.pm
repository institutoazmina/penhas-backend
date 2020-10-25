#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoio;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio");
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
    default_value => "disabled",
    is_nullable => 0,
    size => 20,
  },
  "owner",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "nome",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "sigla",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "natureza",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "categoria",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "descricao",
  { data_type => "text", is_nullable => 1 },
  "tipo_logradouro",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "nome_logradouro",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "numero",
  { data_type => "integer", is_nullable => 1 },
  "numero_sem_numero",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "complemento",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "bairro",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "municipio",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "uf",
  { data_type => "varchar", is_nullable => 0, size => 2 },
  "cep",
  { data_type => "varchar", is_nullable => 0, size => 8 },
  "ddd",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "telefone1",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "telefone2",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "eh_24h",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "horario_inicio",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "horario_fim",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "dias_funcionamento",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "eh_presencial",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "eh_online",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "funcionamento_pandemia",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "observacao_pandemia",
  { data_type => "text", is_nullable => 1 },
  "latitude",
  { data_type => "decimal", is_nullable => 1, size => [22, 6] },
  "longitude",
  { data_type => "decimal", is_nullable => 1, size => [22, 6] },
  "ja_passou_por_moderacao",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "avaliacao",
  { data_type => "float", default_value => 0, is_nullable => 0 },
  "test_status",
  {
    data_type => "varchar",
    default_value => "prod",
    is_nullable => 0,
    size => 20,
  },
  "cliente_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "qtde_avaliacao",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "observacao",
  { data_type => "text", is_nullable => 1 },
  "horario_correto",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "delegacia_mulher",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "endereco_correto",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "telefone_correto",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "existe_delegacia",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "eh_importacao",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "updated_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "indexed_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "index",
  { data_type => "varchar", is_nullable => 1, size => 200 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "categoria",
  "Penhas::Schema2::Result::PontoApoioCategoria",
  { id => "categoria" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
__PACKAGE__->has_many(
  "cliente_ponto_apoio_avaliacaos",
  "Penhas::Schema2::Result::ClientePontoApoioAvaliacao",
  { "foreign.ponto_apoio_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-10-23 21:38:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5TUr2k/1k419fvEdAcpn9w

# ALTER TABLE ponto_apoio ADD FOREIGN KEY (categoria) REFERENCES ponto_apoio_categoria(id);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
