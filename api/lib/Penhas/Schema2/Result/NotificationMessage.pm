#<<<
use utf8;
package Penhas::Schema2::Result::NotificationMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("notification_message");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "is_test",
  {
    data_type => "tinyint",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "title",
  { data_type => "text", is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "meta",
  { data_type => "text", default_value => "'{}'", is_nullable => 0 },
  "subject_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "notification_logs",
  "Penhas::Schema2::Result::NotificationLog",
  { "foreign.notification_message_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-11-07 20:28:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/5CPs4sFm2NiArHqnsPo7Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
