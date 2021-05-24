#<<<
use utf8;
package Penhas::Schema2::Result::CpfErro;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("cpf_erros");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cpf_erros_id_seq",
  },
  "cpf_hash",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cpf_start",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "count",
  { data_type => "bigint", default_value => 1, is_nullable => 0 },
  "reset_at",
  { data_type => "timestamp with time zone", is_nullable => 0 },
  "remote_ip",
  { data_type => "varchar", is_nullable => 0, size => 200 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BXtq8y5NcvUuW7z9xbmeIA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
