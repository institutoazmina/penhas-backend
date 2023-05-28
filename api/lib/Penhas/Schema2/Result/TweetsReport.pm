#<<<
use utf8;
package Penhas::Schema2::Result::TweetsReport;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("tweets_reports");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tweets_reports_id_seq",
  },
  "cliente_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "reported_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "created_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "reason",
  { data_type => "varchar", is_nullable => 0, size => 200 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "reported",
  "Penhas::Schema2::Result::Tweet",
  { id => "reported_id" },
  { is_deferrable => 0, on_delete => "SET NULL", on_update => "NO ACTION" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-05-25 21:16:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3rVRbYte3a1r3/l8ToiD4g

# ALTER TABLE tweets_reports ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
