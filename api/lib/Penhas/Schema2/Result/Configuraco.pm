#<<<
use utf8;
package Penhas::Schema2::Result::Configuraco;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("configuracoes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "termos_de_uso",
  { data_type => "text", is_nullable => 0 },
  "privacidade",
  { data_type => "text", is_nullable => 0 },
  "texto_faq_index",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-02-26 13:11:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AOUnIzxF+hy8mhDRKGOm+w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
