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
  { data_type => "text", is_nullable => 1 },
  "parent_id",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 20,
  },
  "anonimo",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "qtde_reportado",
  { data_type => "bigint", default_value => 0, is_nullable => 1 },
  "qtde_expansoes",
  { data_type => "bigint", default_value => 0, is_nullable => 1 },
  "qtde_likes",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "qtde_comentarios",
  { data_type => "bigint", default_value => 0, is_nullable => 1 },
  "escondido",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "ultimo_comentario_id",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 20,
  },
  "media_ids",
  { data_type => "text", is_nullable => 1 },
  "disable_escape",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "tags_index",
  {
    data_type => "varchar",
    default_value => ",,",
    is_nullable => 0,
    size => 5000,
  },
  "original_parent_id",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->has_many(
  "tweets_likes",
  "Penhas::Schema2::Result::TweetLikes",
  { "foreign.tweet_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pTkJYB4oMHgKFFgiPoXteg

# alter table tweets modify column cliente_id  int(11) unsigned  not null;
# ALTER TABLE tweets ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
