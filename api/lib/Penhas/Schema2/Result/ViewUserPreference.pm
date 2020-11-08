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
__PACKAGE__->result_source_instance->view_definition("select `p`.`name` AS `name`,`c`.`id` AS `cliente_id`,coalesce(`cp`.`value`,`p`.`initial_value`) AS `value` from ((`directus`.`preferences` `p` join `directus`.`clientes` `c`) left join `directus`.`clientes_preferences` `cp` on(`cp`.`cliente_id` = `c`.`id` and `cp`.`preference_id` = `p`.`id`))");
__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cliente_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 200 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-11-07 22:42:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o/X0VJK9RbfSl1PlDx/ZTw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
