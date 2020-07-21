#<<<
use utf8;
package Penhas::Schema2::Result::ClienteAtivacoesPanico;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("cliente_ativacoes_panico");
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
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "alert_sent_to",
  { data_type => "text", default_value => "'{}'", is_nullable => 0 },
  "gps_lat",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "gps_long",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "meta",
  { data_type => "text", is_nullable => 1 },
  "sms_enviados",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-07-04 14:31:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aVic1PhKkB8/gycoiKQpdw

# ALTER TABLE cliente_ativacoes_panico ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;