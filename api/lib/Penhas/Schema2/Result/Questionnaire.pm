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
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "owner",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "modified_by",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "modified_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "active",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "condition",
  {
    data_type => "varchar",
    default_value => "[% 1 %]",
    is_nullable => 0,
    size => 2000,
  },
  "end_screen",
  {
    data_type => "varchar",
    default_value => "home",
    is_nullable => 0,
    size => 200,
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-20 18:21:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5ggSgsjQoYpYOIfTd+UfAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
