#<<<
use utf8;
package Penhas::Schema2::Result::RssFeed;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("rss_feeds");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "rss_feeds_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "url",
  { data_type => "varchar", is_nullable => 0, size => 2000 },
  "next_tick",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "last_run",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "fonte",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "autocapitalize",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "last_error_message",
  { data_type => "text", is_nullable => 1 },
  "owner",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "modified_by",
  { data_type => "uuid", is_nullable => 1, size => 16 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "noticias",
  "Penhas::Schema2::Result::Noticia",
  { "foreign.rss_feed_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-09-09 08:40:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NdASKWpMPzzAfu5RQRmn5A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
