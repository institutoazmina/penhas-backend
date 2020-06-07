#<<<
use utf8;
package Penhas::Schema2::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("tags");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "is_topic",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 0 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "noticias2tags",
  "Penhas::Schema2::Result::Noticias2tag",
  { "foreign.tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "rss_feed_forced_tags",
  "Penhas::Schema2::Result::RssFeedForcedTag",
  { "foreign.tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-04 11:55:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cIwJTgwZOQZwatmD/SyKPg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
