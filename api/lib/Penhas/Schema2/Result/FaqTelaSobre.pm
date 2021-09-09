#<<<
use utf8;
package Penhas::Schema2::Result::FaqTelaSobre;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("faq_tela_sobre");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "faq_tela_sobre_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "sort",
  { data_type => "bigint", is_nullable => 1 },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "content_html",
  { data_type => "text", is_nullable => 0 },
  "fts_categoria_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "exibir_titulo_inline",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "owner",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "modified_by",
  { data_type => "uuid", is_nullable => 1, size => 16 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "fts_categoria",
  "Penhas::Schema2::Result::FaqTelaSobreCategoria",
  { id => "fts_categoria_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-09-09 08:40:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z0M7LpXYvzWgUsHv2BFrmg

# ALTER TABLE faq_tela_sobre ADD FOREIGN KEY (fts_categoria_id) REFERENCES faq_tela_sobre_categoria (id) ON DELETE RESTRICT ON UPDATE RESTRICT;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
