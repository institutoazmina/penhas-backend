#<<<
use utf8;
package Penhas::Schema2::Result::ClientesReport;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_reports");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clientes_reports_id_seq",
  },
  "cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "reported_cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "reason",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "reported_cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "reported_cliente_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-03-04 15:27:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cv3hFnVUfKKCg7sG20X3gQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
