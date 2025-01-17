#<<<
use utf8;
package Penhas::Schema2::Result::TweetLikes;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("tweets_likes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tweets_likes_id_seq",
  },
  "created_on",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "tweet_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "tweet",
  "Penhas::Schema2::Result::Tweet",
  { id => "tweet_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-04-06 00:11:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cKIZ9XZFA1D+ivZ11E1M1A

# alter table tweets_likes modify column cliente_id  int(11) unsigned  not null;
# delete from tweets_likes where cliente_id not in (select id from clientes);
# ALTER TABLE tweets_likes ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# delete from tweets_likes where tweet_id not in (select id from tweets);
# ALTER TABLE tweets_likes ADD FOREIGN KEY (tweet_id) REFERENCES tweets(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
