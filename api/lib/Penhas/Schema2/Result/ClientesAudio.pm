#<<<
use utf8;
package Penhas::Schema2::Result::ClientesAudio;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_audios");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clientes_audios_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "played_count",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "cliente_created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "media_upload_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 200 },
  "event_id",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "event_sequence",
  { data_type => "integer", is_nullable => 0 },
  "waveform_base64",
  { data_type => "text", is_nullable => 1 },
  "audio_duration",
  { data_type => "double precision", is_nullable => 0 },
  "duplicated_upload",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "first_downloaded_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "media_upload",
  "Penhas::Schema2::Result::MediaUpload",
  { id => "media_upload_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:T7xC/KZAiw3fAOWOjb8f1Q

# ALTER TABLE clientes_audios ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE clientes_audios ADD FOREIGN KEY (media_upload_id) REFERENCES media_upload(id) ON DELETE CASCADE ON UPDATE cascade;

__PACKAGE__->belongs_to(
  "clientes_audio_evento",
  "Penhas::Schema2::Result::ClientesAudiosEvento",
  { event_id => "event_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
