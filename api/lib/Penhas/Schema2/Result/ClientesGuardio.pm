#<<<
use utf8;
package Penhas::Schema2::Result::ClientesGuardio;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_guardioes");
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
  "status",
  {
    data_type => "varchar",
    default_value => "pending",
    is_nullable => 0,
    size => 20,
  },
  "apelido",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "celular_e164",
  { data_type => "varchar", is_nullable => 0, size => 25 },
  "nome",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "token",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "accepted_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "accepted_meta",
  { data_type => "text", default_value => "'{}'", is_nullable => 0 },
  "celular_formatted_as_national",
  { data_type => "varchar", is_nullable => 0, size => 25 },
  "refused_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "deleted_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "expires_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("token", ["token"]);
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-28 07:56:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MTDTtNhfs3G6rbgCeFCpkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
