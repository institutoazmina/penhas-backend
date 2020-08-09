#<<<
use utf8;
package Penhas::Schema2::Result::ClientePontoApoioAvaliacao;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("cliente_ponto_apoio_avaliacao");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cliente_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "ponto_apoio_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "avaliacao",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-08 23:01:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0r22WRI6UITT5k8YfjSBpQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
