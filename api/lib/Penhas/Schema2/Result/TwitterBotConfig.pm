#<<<
use utf8;
package Penhas::Schema2::Result::TwitterBotConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("twitter_bot_config");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "twitter_bot_config_id_seq",
  },
  "user_created",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "date_created",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "user_updated",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "date_updated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "config",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-07-01 16:32:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:w9YD9VordFTKwBhWFQIvDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
