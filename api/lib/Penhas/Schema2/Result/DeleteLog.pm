#<<<
use utf8;
package Penhas::Schema2::Result::DeleteLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("delete_log");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "data",
  { data_type => "text", default_value => "'{}'", is_nullable => 0 },
  "email_md5",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-11-02 17:32:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9b3FY1zND7KtTkt9H6mr2A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
