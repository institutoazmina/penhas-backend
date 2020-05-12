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
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cpf_hash",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cpf_start",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "count",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "reset_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "remote_ip",
  { data_type => "varchar", is_nullable => 0, size => 200 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-05-12 05:30:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Mahu4VyJsmUO8A068xvOeA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
