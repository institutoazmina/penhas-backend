#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoio2projeto;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio2projetos");
__PACKAGE__->add_columns(
  "ponto_apoio_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ponto_apoio_projeto_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("ponto_apoio_id", "ponto_apoio_projeto_id");
__PACKAGE__->belongs_to(
  "ponto_apoio",
  "Penhas::Schema2::Result::PontoApoio",
  { id => "ponto_apoio_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "ponto_apoio_projeto",
  "Penhas::Schema2::Result::PontoApoioProjeto",
  { id => "ponto_apoio_projeto_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-03-24 12:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J1/0TK3XiD2/gwoOPpTrvQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
