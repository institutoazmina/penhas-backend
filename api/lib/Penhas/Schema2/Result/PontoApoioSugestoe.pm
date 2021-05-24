#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoioSugestoe;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio_sugestoes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ponto_apoio_sugestoes_id_seq",
  },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "endereco_ou_cep",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "nome",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "categoria",
  { data_type => "bigint", is_nullable => 0 },
  "descricao_servico",
  { data_type => "text", is_nullable => 0 },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "metainfo",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pMJWj6FzzMjtiCflo+cb7w

# ALTER TABLE ponto_apoio_sugestoes ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
