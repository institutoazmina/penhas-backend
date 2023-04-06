#<<<
use utf8;
package Penhas::Schema2::Result::MfClienteTarefa;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("mf_cliente_tarefa");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mf_cliente_tarefa_id_seq",
  },
  "mf_tarefa_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "checkbox_feito",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "checkbox_feito_checked_first_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "checkbox_feito_checked_last_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "checkbox_feito_unchecked_first_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "checkbox_feito_unchecked_last_updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "criado_em",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "removido_em",
  { data_type => "timestamp", is_nullable => 1 },
  "last_from_questionnaire",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "atualizado_em",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "last_from_questionnaire",
  "Penhas::Schema2::Result::Questionnaire",
  { id => "last_from_questionnaire" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->belongs_to(
  "mf_tarefa",
  "Penhas::Schema2::Result::MfTarefa",
  { id => "mf_tarefa_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-04-06 00:11:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QCSRlN1YSpqPRtXCb5x9rw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
