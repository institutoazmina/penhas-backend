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
  "ultimo_comentario_id",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "media_ids",
  { data_type => "text", is_nullable => 1 },
  "disable_escape",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "tags_index",
  {
    data_type => "varchar",
    default_value => ",,",
    is_nullable => 0,
    size => 5000,
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-06-20 21:04:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kU2WvsuNqndSZ+cUDMCwrg


__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->has_many(
  "tweet_likes",
  "Penhas::Schema2::Result::TweetLikes",
  { "foreign.tweet_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
