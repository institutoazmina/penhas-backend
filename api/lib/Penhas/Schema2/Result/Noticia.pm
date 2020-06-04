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
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
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
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-03 16:48:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/lwDCwinILKvK42HtNfCOQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
