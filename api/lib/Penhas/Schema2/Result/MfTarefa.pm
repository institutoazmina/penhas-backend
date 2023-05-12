#<<<
use utf8;
package Penhas::Schema2::Result::MfTarefa;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("mf_tarefa");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mf_tarefa_id_seq",
  },
  "titulo",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "descricao",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "tipo",
  {
    data_type     => "text",
    default_value => "checkbox",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "codigo",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "criado_em",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "eh_customizada",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "campo_livre_1",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "campo_livre_2",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "campo_livre_3",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "agrupador",
  {
    data_type => "varchar",
    default_value => "Outros",
    is_nullable => 0,
    size => 120,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "mf_cliente_tarefas",
  "Penhas::Schema2::Result::MfClienteTarefa",
  { "foreign.mf_tarefa_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-05-20 07:58:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6BHCs3J2P24LrPOtl1prfw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;