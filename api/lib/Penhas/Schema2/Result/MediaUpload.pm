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
  { data_type => "text", is_nullable => 1 },
  "file_sha1",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "file_size",
  { data_type => "bigint", is_nullable => 1 },
  "s3_path",
  { data_type => "text", is_nullable => 0 },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "intention",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "s3_path_avatar",
  { data_type => "text", is_nullable => 1 },
  "file_size_avatar",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
__PACKAGE__->has_many(
  "clientes_audios",
  "Penhas::Schema2::Result::ClientesAudio",
  { "foreign.media_upload_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X+Oto6n0uZzuJ/OWezrhAA

# ALTER TABLE media_upload ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT ON UPDATE RESTRICT;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
