#<<<
use utf8;
package Penhas::Schema2::Result::QuizConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("quiz_config");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "quiz_config_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "sort",
  { data_type => "bigint", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "code",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "question",
  { data_type => "varchar", is_nullable => 0, size => 800 },
  "questionnaire_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "yesnogroup",
  { data_type => "json", default_value => "{}", is_nullable => 1 },
  "intro",
  { data_type => "json", default_value => "{}", is_nullable => 1 },
  "relevance",
  { data_type => "varchar", default_value => 1, is_nullable => 0, size => 2000 },
  "button_label",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "modified_by",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "options",
  { data_type => "json", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "questionnaire",
  "Penhas::Schema2::Result::Questionnaire",
  { id => "questionnaire_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-31 11:55:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pguDhXSX/uUmXBph/2XcIA

# ALTER TABLE quiz_config ADD FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(id) ON DELETE CASCADE ON UPDATE cascade;
=pod

delimiter //
create trigger `quiz_config_after_update` after update on `quiz_config`
for each row
begin
 update questionnaires
 set modified_on = now()
 where id = NEW.questionnaire_id OR id = OLD.questionnaire_id;
end;//

delimiter ;

=cut

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
