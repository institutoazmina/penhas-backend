#<<<
use utf8;
package Penhas::Schema2::Result::ChatClientesNotification;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("chat_clientes_notifications");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "chat_clientes_notifications_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "messaged_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "notification_created",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "pending_message_cliente_id",
  { data_type => "bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VKQivbChTQ/ZXnIzRt1pLA

# ALTER TABLE chat_clientes_notifications ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# CREATE INDEX idx_chat_clientes_notifications ON chat_clientes_notifications(messaged_at);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
