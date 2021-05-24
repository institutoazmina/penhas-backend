#<<<
use utf8;
package Penhas::Schema2::Result::ViewUserPreference;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("view_user_preferences");
__PACKAGE__->result_source_instance->view_definition(" SELECT p.name,\n    c.id AS cliente_id,\n    COALESCE(cp.value, p.initial_value) AS value\n   FROM ((preferences p\n     CROSS JOIN clientes c)\n     LEFT JOIN clientes_preferences cp ON (((cp.cliente_id = c.id) AND (cp.preference_id = p.id))))");
__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "cliente_id",
  { data_type => "bigint", is_nullable => 1 },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 200 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 17:24:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NxQV0bgxpuGOilRlGpbWTg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
