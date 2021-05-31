#<<<
use utf8;
package Penhas::Schema2::Result::Questionnaire;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("questionnaires");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "questionnaires_id_seq",
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "active",
  { data_type => "boolean", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "condition",
  { data_type => "varchar", default_value => 0, is_nullable => 0, size => 2000 },
  "end_screen",
  {
    data_type => "varchar",
    default_value => "home",
    is_nullable => 0,
    size => 200,
  },
  "owner",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "modified_by",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "penhas_start_automatically",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "penhas_cliente_required",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "anonymous_quiz_sessions",
  "Penhas::Schema2::Result::AnonymousQuizSession",
  { "foreign.questionnaire_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "quiz_configs",
  "Penhas::Schema2::Result::QuizConfig",
  { "foreign.questionnaire_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-31 15:13:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BwXh0aVH9ZzBT62SlFgwQg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
