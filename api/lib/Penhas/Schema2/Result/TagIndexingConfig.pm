#<<<
use utf8;
package Penhas::Schema2::Result::TagIndexingConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("tag_indexing_config");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "owner",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "prod",
    is_nullable => 0,
    size => 20,
  },
  "tag_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "page_title_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "page_title_not_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "html_article_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "html_article_not_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "page_description_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "page_description_not_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "url_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "url_not_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "rss_feed_tags_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "rss_feed_tags_not_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "rss_feed_content_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "rss_feed_content_not_match",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "regexp",
  {
    data_type => "tinyint",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "verified",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "error_msg",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 3 },
  "verified_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "modified_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-05 10:36:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EigsosuED7g39Cg0PolMvA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
