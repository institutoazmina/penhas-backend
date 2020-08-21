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
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "sort",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "modified_by",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "modified_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "code",
  { data_type => "tinytext", is_nullable => 0 },
  "question",
  { data_type => "varchar", is_nullable => 0, size => 800 },
  "questionnaire_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "yesnogroup",
  { data_type => "text", is_nullable => 1 },
  "intro",
  { data_type => "text", is_nullable => 1 },
  "relevance",
  { data_type => "varchar", default_value => 1, is_nullable => 0, size => 2000 },
  "button_label",
  { data_type => "varchar", is_nullable => 1, size => 200 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-20 18:21:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wSlK4R2ZnVXIM7WdRJqLHw

# ALTER TABLE quiz_config ADD FOREIGN KEY (questionnaire_id) REFERENCES questionnaires(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
