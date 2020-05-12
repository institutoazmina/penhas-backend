#<<<
use utf8;
package Penhas::Schema2::Result::LoginLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("login_logs");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "remote_ip",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cliente_id",
  { data_type => "integer", is_nullable => 1 },
  "mastodon_oauth2_id",
  { data_type => "integer", is_nullable => 1 },
  "app_version",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-05-12 05:30:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+oYkfrartrULiWobUE4pNA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;