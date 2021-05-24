#<<<
use utf8;
package Penhas::Schema2::Result::ClientesPreference;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_preferences");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clientes_preferences_id_seq",
  },
  "value",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "updated_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "preference_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "preference",
  "Penhas::Schema2::Result::Preference",
  { id => "preference_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t4K90BBQKLhA9LZX5/qVPQ

# ALTER TABLE clientes_preferences ADD FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE clientes_preferences ADD FOREIGN KEY (preference_id) REFERENCES preferences (id) ON DELETE RESTRICT ON UPDATE RESTRICT;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
