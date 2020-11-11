#<<<
use utf8;
package Penhas::Schema2::Result::ClientesAppNotification;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_app_notifications");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cliente_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "read_until",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-11-10 22:31:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qr1Jv0qZmWy5Fjmv/u2yPw

# ALTER TABLE clientes_app_notifications ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE clientes_app_notifications DROP COLUMN read_until;
# ALTER TABLE clientes_app_notifications ADD COLUMN read_until datetime(6) not null;


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
