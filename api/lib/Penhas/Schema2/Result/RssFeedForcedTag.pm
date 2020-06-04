#<<<
use utf8;
package Penhas::Schema2::Result::RssFeedForcedTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("rss_feed_forced_tags");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "rss_feed_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "tag_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-03 07:52:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RZ6T83u6d9NLE3NhigyPNA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
