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
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 2000 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "media_ids",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "display_created_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "hyperlink",
  { data_type => "text", is_nullable => 1 },
  "indexed",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "indexed_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "logs",
  { data_type => "mediumtext", is_nullable => 1 },
  "rss_feed_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "author",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "info",
  { data_type => "text", default_value => "'{}'", is_nullable => 0 },
  "fonte",
  { data_type => "text", is_nullable => 1 },
  "published",
  {
    data_type => "varchar",
    default_value => "hidden",
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "noticias2tags",
  "Penhas::Schema2::Result::Noticias2tag",
  { "foreign.noticias_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "rss_feed",
  "Penhas::Schema2::Result::RssFeed",
  { id => "rss_feed_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-04 20:32:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CbuhcMjKQo9HeLsx6UM2Ig

# ALTER TABLE noticias ADD FOREIGN KEY (rss_feed_id) REFERENCES rss_feeds(id) ON DELETE CASCADE ON UPDATE cascade;


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
