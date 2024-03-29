#<<<
use utf8;
package Penhas::Schema2::Result::AdminBigNumber;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("admin_big_numbers");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "admin_big_numbers_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "sort",
  { data_type => "bigint", is_nullable => 1 },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "label",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "comment",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "sql",
  { data_type => "text", is_nullable => 0 },
  "background_class",
  {
    data_type => "varchar",
    default_value => "bg-light",
    is_nullable => 0,
    size => 100,
  },
  "text_class",
  {
    data_type => "varchar",
    default_value => "text-dark",
    is_nullable => 0,
    size => 100,
  },
  "owner_new",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "modified_by_new",
  { data_type => "uuid", is_nullable => 1, size => 16 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5GM1AJaaxdHFVAoJKR0V5Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
