#<<<
use utf8;
package Penhas::Schema2::Result::ClientesAppActivity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_app_activity");
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
  "last_tm_activity",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "last_activity",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("cliente_id", ["cliente_id"]);
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-23 12:47:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O6JhUrsJDAi4yMk81uxZuA

# ALTER TABLE clientes_app_activity ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# alter table  clientes_app_activity modify column last_tm_activity datetime(6);
# alter table  clientes_app_activity modify column last_activity datetime(6);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
