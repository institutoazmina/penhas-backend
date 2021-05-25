#<<<
use utf8;
package Penhas::Schema2::Result::ClientesAudiosEvento;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_audios_eventos");
__PACKAGE__->add_columns(
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "event_id",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "audio_duration",
  { data_type => "numeric", is_nullable => 0, size => [10, 5] },
  "updated_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "status",
  {
    data_type => "varchar",
    default_value => "free_access",
    is_nullable => 0,
    size => 20,
  },
  "requested_by_user",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "total_bytes",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "last_cliente_created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "requested_by_user_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "deleted_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("event_id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-25 03:33:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xdk4evyUXncLG5xyvEfGcg

# ALTER TABLE clientes_audios_eventos ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;

__PACKAGE__->has_many(
    "cliente_audios",
    "Penhas::Schema2::Result::ClientesAudio",
    {"foreign.event_id" => "self.event_id"},
    {cascade_copy       => 0, cascade_delete => 0},
);

sub fake_event_id {
    my (undef, $event_id) = split /\:/, shift->event_id();
    return $event_id;
}

sub is_download_granted {
    my ($self) = @_;
    return $self->status() =~ /^(free_access|free_access_by_admin)$/ ? 1 : 0;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
