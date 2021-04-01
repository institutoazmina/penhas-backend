#<<<
use utf8;
package Penhas::Schema::Result::CpfCache;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("cpf_cache");
__PACKAGE__->add_columns(
  "cpf_hashed",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "dt_nasc",
  { data_type => "date", is_nullable => 0 },
  "nome_hashed",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "situacao",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "genero",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 200,
  },
  "__created_at_real",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("cpf_hashed", "dt_nasc");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-01 17:05:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7HetIoRL1f+FOfwt691++w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
