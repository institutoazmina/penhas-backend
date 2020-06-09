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
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "tag_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "rss_feed",
  "Penhas::Schema2::Result::RssFeed",
  { id => "rss_feed_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "tag",
  "Penhas::Schema2::Result::Tag",
  { id => "tag_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-04 11:53:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zW6OqYrsUwHNQVsyJQDmhQ

# ALTER TABLE rss_feed_forced_tags ADD FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE rss_feed_forced_tags ADD FOREIGN KEY (rss_feed_id) REFERENCES rss_feeds(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;