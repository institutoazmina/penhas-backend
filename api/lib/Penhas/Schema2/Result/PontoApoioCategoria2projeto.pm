#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoioCategoria2projeto;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio_categoria2projetos");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "ponto_apoio_categoria_id",
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
  "ponto_apoio_categoria",
  "Penhas::Schema2::Result::PontoApoioCategoria",
  { id => "ponto_apoio_categoria_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "ponto_apoio_projeto",
  "Penhas::Schema2::Result::PontoApoioProjeto",
  { id => "ponto_apoio_projeto_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-10-23 16:06:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E1EiHyjBgWsYKUtDQ0EEPw

# ALTER TABLE ponto_apoio_categoria2projetos ADD FOREIGN KEY (ponto_apoio_categoria_id) REFERENCES ponto_apoio_categoria(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE ponto_apoio_categoria2projetos ADD FOREIGN KEY (ponto_apoio_projeto_id) REFERENCES ponto_apoio_projeto(id) ON DELETE CASCADE ON UPDATE cascade;

=pod

delimiter //
create trigger `ponto_apoio_categoria2projetos_after_update` after update on `ponto_apoio_categoria2projetos`
for each row
begin
 update ponto_apoio
 set indexed_at = null
 where categoria = NEW.ponto_apoio_categoria_id OR categoria = OLD.ponto_apoio_categoria_id;
end;//

create trigger `ponto_apoio_categoria2projetos_after_insert` after insert on `ponto_apoio_categoria2projetos`
for each row
begin
 update ponto_apoio
 set indexed_at = null
 where categoria = NEW.ponto_apoio_categoria_id;
end;//

create trigger `ponto_apoio_categoria2projetos_after_delete` after delete on `ponto_apoio_categoria2projetos`
for each row
begin
 update ponto_apoio
 set indexed_at = null
 where categoria = OLD.ponto_apoio_categoria_id;
end;//

delimiter ;

=cut

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
