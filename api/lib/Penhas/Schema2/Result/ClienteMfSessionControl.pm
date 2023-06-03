#<<<
use utf8;
package Penhas::Schema2::Result::ClienteMfSessionControl;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("cliente_mf_session_control");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cliente_mf_session_control_id_seq",
  },
  "cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status",
  {
    data_type     => "text",
    default_value => "onboard",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "current_clientes_quiz_session",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "completed_questionnaires_id",
  {
    data_type     => "integer[]",
    default_value => \"'{}'::integer[]",
    is_nullable   => 0,
  },
  "started_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "completed_at",
  { data_type => "timestamp", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "current_clientes_quiz_session",
  "Penhas::Schema2::Result::ClientesQuizSession",
  { id => "current_clientes_quiz_session" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-05-25 18:44:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DI5WCEpbMHdtmSO2Ssohsw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
