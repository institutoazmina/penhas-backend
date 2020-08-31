#<<<
use utf8;
package Penhas::Schema2::Result::ChatSupport;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("chat_support");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cliente_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "last_msg_is_support",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "last_msg_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("idx_uniq_chat_support_cliente", ["cliente_id"]);
__PACKAGE__->has_many(
  "chat_support_messages",
  "Penhas::Schema2::Result::ChatSupportMessage",
  { "foreign.chat_support_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-31 12:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Vf0dDfFyyRJ9GFhaYUAe4Q

# ALTER TABLE chat_support ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;
# alter table chat_support modify column created_at datetime(6);
# alter table chat_support modify column last_msg_at datetime(6);
# alter table chat_support modify column last_msg_at datetime(6);
# CREATE UNIQUE INDEX idx_uniq_chat_support_cliente ON chat_support(cliente_id);



# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
