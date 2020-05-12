#<<<
use utf8;
package Penhas::Schema2::Result::Tweet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("tweets");
__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "content",
  { data_type => "varchar", is_nullable => 1, size => 2000 },
  "parent_id",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "anonimo",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "qtde_reportado",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "qtde_expansoes",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "qtde_likes",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "qtde_comentarios",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "escondido",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "cliente_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-05-12 05:30:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LyV4liO5nfiKH4MupdlneQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
