#<<<
use utf8;
package Penhas::Schema::Result::ChatSession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("chat_session");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "chat_session_id_seq",
  },
  "salt",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "participants",
  { data_type => "integer[]", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "last_message_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "chat_messages",
  "Penhas::Schema::Result::ChatMessage",
  { "foreign.chat_session" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-17 10:23:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Fz0UseCIoGOkw3p7N568uA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
