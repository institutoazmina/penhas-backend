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
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cliente_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "other_cliente_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "started_at",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-11-28 21:22:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G7hukw4ttaMO89cKb2SE1w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
