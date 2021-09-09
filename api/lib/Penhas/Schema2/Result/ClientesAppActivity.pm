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
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clientes_app_activity_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "last_tm_activity",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "last_activity",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("idx_25942_cliente_id", ["cliente_id"]);
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-09-09 08:40:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y7joTR4lFSortpgX31UXuA

# ALTER TABLE clientes_app_activity ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# alter table  clientes_app_activity modify column last_tm_activity datetime(6);
# alter table  clientes_app_activity modify column last_activity datetime(6);
# CREATE INDEX idx_last_tm_activity_desc ON clientes_app_activity (last_tm_activity  desc);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
