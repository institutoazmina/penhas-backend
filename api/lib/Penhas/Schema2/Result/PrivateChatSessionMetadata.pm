#<<<
use utf8;
package Penhas::Schema2::Result::PrivateChatSessionMetadata;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("private_chat_session_metadata");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "private_chat_session_metadata_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_nullable => 0 },
  "other_cliente_id",
  { data_type => "bigint", is_nullable => 0 },
  "started_at",
  { data_type => "date", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5wwHg8/Le4sR8JRejl33Lw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
