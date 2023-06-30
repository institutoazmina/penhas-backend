#<<<
use utf8;
package Penhas::Schema2::Result::NoticiasTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("noticias_tags");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "noticias_tags_id_seq",
  },
  "noticias_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "tags_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "noticia",
  "Penhas::Schema2::Result::Noticia",
  { id => "noticias_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->belongs_to(
  "tag",
  "Penhas::Schema2::Result::Tag",
  { id => "tags_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-05-25 21:16:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TW7erURgbQNibmSM6RrXGA

# ALTER TABLE noticias_tags ADD FOREIGN KEY (tags_id) REFERENCES tags(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE noticias_tags ADD FOREIGN KEY (noticias_id) REFERENCES noticias(id) ON DELETE CASCADE ON UPDATE cascade;

__PACKAGE__->belongs_to(
  "noticia",
  "Penhas::Schema2::Result::Noticia",
  { id => "noticias_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

__PACKAGE__->belongs_to(
  "tag",
  "Penhas::Schema2::Result::Tag",
  { id => "tags_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

__PACKAGE__->belongs_to(
  "noticia",
  "Penhas::Schema2::Result::Noticia",
  { id => "noticias_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

__PACKAGE__->belongs_to(
  "tag",
  "Penhas::Schema2::Result::Tag",
  { id => "tags_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
