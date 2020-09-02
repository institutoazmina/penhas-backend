#<<<
use utf8;
package Penhas::Schema::Result::ChatMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("chat_message");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "chat_message_id_seq",
  },
  "is_compressed",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "chat_session_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cliente_id",
  { data_type => "integer", is_nullable => 0 },
  "message",
  { data_type => "bytea", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "chat_session",
  "Penhas::Schema::Result::ChatSession",
  { id => "chat_session_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-02 02:29:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NG/Ez2A5uu7ytTAZ+l+Xag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
