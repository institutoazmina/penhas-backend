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
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "delete_log_id_seq",
  },
  "data",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
  "email_md5",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lLtuJcB0cEjyeBe3mFqArA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
