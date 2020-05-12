#<<<
use utf8;
package Penhas::Schema2::Result::ClientesResetPassword;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_reset_password");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cliente_id",
  { data_type => "integer", is_nullable => 0 },
  "token",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "valid_until",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "used_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "requested_by_remote_ip",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "used_by_remote_ip",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-05-12 05:30:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RMtxauv+fKysO0rEv3Fokg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
