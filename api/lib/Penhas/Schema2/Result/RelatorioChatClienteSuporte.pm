#<<<
use utf8;
package Penhas::Schema2::Result::RelatorioChatClienteSuporte;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("relatorio_chat_cliente_suporte");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "relatorio_chat_cliente_suporte_id_seq",
  },
  "cliente_id",
  { data_type => "integer", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-03-24 12:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3Pa7lWA1nrp2r5WE1qpXUA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
