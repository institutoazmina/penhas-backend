#<<<
use utf8;
package Penhas::Schema2::Result::Cliente;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes");
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
    default_value => "setup",
    is_nullable => 0,
    size => 20,
  },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "cpf_hash",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cpf_prefix",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "dt_nasc",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cep",
  { data_type => "varchar", is_nullable => 0, size => 8 },
  "cep_cidade",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "cep_estado",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "genero",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "raca",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "minibio",
  { data_type => "varchar", is_nullable => 1, size => 2200 },
  "nome_completo",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "login_status",
  { data_type => "varchar", default_value => "OK", is_nullable => 1, size => 20 },
  "login_status_last_blocked_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "senha_falsa_sha256",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "ja_foi_vitima_de_violencia",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 1 },
  "esta_em_situcao_de_violencia",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 1 },
  "senha_sha256",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "modo_camuflado_ativo",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "modo_anonimo_ativo",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "esta_em_situcao_de_violencia_atualizado_em",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "ja_foi_vitima_de_violencia_atualizado_em",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "qtde_login_senha_normal",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "qtde_login_senha_falsa",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "apelido",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "nome_social",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "avatar_url",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "genero_outro",
  { data_type => "varchar", is_nullable => 1, size => 200 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("cpf_hash", ["cpf_hash"]);
__PACKAGE__->add_unique_constraint("email", ["email"]);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-05-12 05:30:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aAhp0u5ihUqw/6+2Tx7UXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;