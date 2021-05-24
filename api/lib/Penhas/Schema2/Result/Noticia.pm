#<<<
use utf8;
package Penhas::Schema2::Result::Noticia;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("noticias");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "noticias_id_seq",
  },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 2000 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "display_created_time",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "hyperlink",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "indexed",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "indexed_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "rss_feed_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "author",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "info",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
  "fonte",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "published",
  {
    data_type => "varchar",
    default_value => "hidden",
    is_nullable => 1,
    size => 20,
  },
  "logs",
  { data_type => "text", is_nullable => 1 },
  "image_hyperlink",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "tags_index",
  {
    data_type => "varchar",
    default_value => ",,",
    is_nullable => 0,
    size => 2000,
  },
  "has_topic_tags",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "noticias_tags",
  "Penhas::Schema2::Result::NoticiasTag",
  { "foreign.noticias_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "rss_feed",
  "Penhas::Schema2::Result::RssFeed",
  { id => "rss_feed_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 17:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b/Ey43nWxyMTej1eUckV5w

# ALTER TABLE noticias ADD FOREIGN KEY (rss_feed_id) REFERENCES rss_feeds(id) ON DELETE CASCADE ON UPDATE cascade;


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
