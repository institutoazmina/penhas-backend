#<<<
use utf8;
package Penhas::Schema2::Result::MediaUpload;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("media_upload");
__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "file_info",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "file_sha1",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "file_size",
  { data_type => "integer", is_nullable => 1 },
  "s3_path",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cliente_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "intention",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "s3_path_avatar",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "file_size_avatar",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-05-18 00:31:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JeG3vqQJqIem+GGR/28+8Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;