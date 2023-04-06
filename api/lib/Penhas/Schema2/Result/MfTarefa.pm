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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "mf_cliente_tarefas",
  "Penhas::Schema2::Result::MfClienteTarefa",
  { "foreign.mf_tarefa_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-04-06 00:11:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cp9btOv1OkehO1IZ/e3ylw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
