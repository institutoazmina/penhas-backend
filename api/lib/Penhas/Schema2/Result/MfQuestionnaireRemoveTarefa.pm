#<<<
use utf8;
package Penhas::Schema2::Result::MfQuestionnaireRemoveTarefa;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("mf_questionnaire_remove_tarefa");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mf_questionnaire_remove_tarefa_id_seq",
  },
  "questionnaire_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "codigo_tarefa",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "questionnaire",
  "Penhas::Schema2::Result::Questionnaire",
  { id => "questionnaire_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2024-02-01 12:18:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gGX8I9dKx92uTAaesk7Aqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
