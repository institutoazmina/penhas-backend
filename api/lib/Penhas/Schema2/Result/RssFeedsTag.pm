#<<<
use utf8;
package Penhas::Schema2::Result::RssFeedsTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("rss_feeds_tags");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "rss_feeds_tags_id_seq",
  },
  "tags_id",
  { data_type => "bigint", is_nullable => 1 },
  "rss_feeds_id",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-09-09 08:40:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M16UeBbZw8ogTZF2w29MPw

# ALTER TABLE rss_feeds_tags ADD FOREIGN KEY (tags_id) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE rss_feeds_tags ADD FOREIGN KEY (rss_feeds_id) REFERENCES rss_feeds(id) ON DELETE CASCADE ON UPDATE cascade;


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
