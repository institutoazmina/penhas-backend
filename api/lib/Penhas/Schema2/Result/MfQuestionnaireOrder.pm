#<<<
use utf8;
package Penhas::Schema2::Result::MfQuestionnaireOrder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("mf_questionnaire_order");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mf_questionnaire_order_id_seq",
  },
  "sort",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "outstanding_order",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_last",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "published",
  {
    data_type => "varchar",
    default_value => "testing",
    is_nullable => 1,
    size => 20,
  },
  "questionnaire_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "questionnaire",
  "Penhas::Schema2::Result::Questionnaire",
  { id => "questionnaire_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-06-28 12:27:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4OhL9yrw7tk0YAdMuLYX1A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
