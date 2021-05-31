#<<<
use utf8;
package Penhas::Schema2::Result::AnonymousQuizSession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("anonymous_quiz_session");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "anonymous_quiz_session_id_seq",
  },
  "remote_id",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "questionnaire_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "finished_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "stash",
  { data_type => "json", default_value => "{}", is_nullable => 1 },
  "responses",
  { data_type => "json", default_value => "{}", is_nullable => 1 },
  "deleted_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "questionnaire",
  "Penhas::Schema2::Result::Questionnaire",
  { id => "questionnaire_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-31 15:03:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XDE9eksB+JOMWlnYDn2H5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
