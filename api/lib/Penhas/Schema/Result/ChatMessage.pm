#<<<
use utf8;
package Penhas::Schema::Result::ChatMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("chat_messages");
__PACKAGE__->add_columns(
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "chat_session",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "message_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "cliente_id",
  { data_type => "integer", is_nullable => 0 },
  "message",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("created_at", "chat_session", "message_id");
__PACKAGE__->belongs_to(
  "chat_session",
  "Penhas::Schema::Result::ChatSession",
  { id => "chat_session" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-17 09:08:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d1T4AQxt8GJut1FitJgL2g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
