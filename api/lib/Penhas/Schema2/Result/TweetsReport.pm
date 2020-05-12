#<<<
use utf8;
package Penhas::Schema2::Result::TweetsReport;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("tweets_reports");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cliente_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "reported_id",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "reason",
  { data_type => "varchar", is_nullable => 0, size => 200 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-05-12 05:30:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/nCpX5m10eKk3g0ZT57Tbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
