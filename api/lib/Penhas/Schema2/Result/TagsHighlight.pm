#<<<
use utf8;
package Penhas::Schema2::Result::TagsHighlight;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("tags_highlight");
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
  "owner",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "created_on",
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
  "tag_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "match",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "is_regexp",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "error_msg",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 200 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "tag",
  "Penhas::Schema2::Result::Tag",
  { id => "tag_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-17 00:03:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0n02dp+FuK1mhsoamMeCbA

# ALTER TABLE tags_highlight ADD FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
