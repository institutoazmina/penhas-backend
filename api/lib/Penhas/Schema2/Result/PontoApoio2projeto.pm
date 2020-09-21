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
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "ponto_apoio_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ponto_apoio_projeto_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "ponto_apoio",
  "Penhas::Schema2::Result::PontoApoio",
  { id => "ponto_apoio_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "ponto_apoio_projeto",
  "Penhas::Schema2::Result::PontoApoioProjeto",
  { id => "ponto_apoio_projeto_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-21 19:23:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7dsdfY6HJpz1Vcl6RCVkJw

# delete from ponto_apoio2projetos where ponto_apoio_projeto_id not in (select id from ponto_apoio_projeto);
# delete from ponto_apoio2projetos where ponto_apoio_id not in (select id from ponto_apoio);

# ALTER TABLE ponto_apoio2projetos ADD FOREIGN KEY (ponto_apoio_id) REFERENCES ponto_apoio(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE ponto_apoio2projetos ADD FOREIGN KEY (ponto_apoio_projeto_id) REFERENCES ponto_apoio_projeto(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
