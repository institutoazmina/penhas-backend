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
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "event_id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "audio_duration",
  { data_type => "double precision", is_nullable => 0 },
  "updated_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "free_access",
    is_nullable => 0,
    size => 20,
  },
  "requested_by_user",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("event_id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-07-23 05:24:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BoeUWGAKZdx4xM2axgGoWg

# ALTER TABLE clientes_audios_eventos ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
