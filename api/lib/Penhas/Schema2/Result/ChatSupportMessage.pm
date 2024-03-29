#<<<
use utf8;
package Penhas::Schema2::Result::ChatSupportMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("chat_support_message");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "chat_support_message_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "chat_support_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "admin_user_id_directus8",
  { data_type => "bigint", is_nullable => 1 },
  "message",
  { data_type => "text", is_nullable => 0 },
  "admin_user_id",
  { data_type => "uuid", is_nullable => 1, size => 16 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "chat_support",
  "Penhas::Schema2::Result::ChatSupport",
  { id => "chat_support_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-25 04:34:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v/KRJLnpgbxxYsiGbdeP6Q

# ALTER TABLE chat_support_message ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# ALTER TABLE chat_support_message ADD FOREIGN KEY (chat_support_id) REFERENCES chat_support(id) ON DELETE CASCADE ON UPDATE cascade;
# alter table chat_support_message modify column created_at datetime(6);
# CREATE INDEX idx_chat_support_created_at ON chat_support(cliente_id, created_at DESC);



# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
