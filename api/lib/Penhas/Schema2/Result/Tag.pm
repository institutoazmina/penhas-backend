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
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tags_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "prod",
    is_nullable => 0,
    size => 20,
  },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "is_topic",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "show_on_filters",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "topic_order",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "rss_feeds_tags",
  "Penhas::Schema2::Result::RssFeedsTag",
  { "foreign.tags_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tag_indexing_configs",
  "Penhas::Schema2::Result::TagIndexingConfig",
  { "foreign.tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tags_highlights",
  "Penhas::Schema2::Result::TagsHighlight",
  { "foreign.tag_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-02-24 10:24:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u+tnR4CpknYNvGBpUUrowg

__PACKAGE__->has_many(
  "noticias_tags",
  "Penhas::Schema2::Result::NoticiasTag",
  { "foreign.tags_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "noticias_tags",
  "Penhas::Schema2::Result::NoticiasTag",
  { "foreign.tags_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
