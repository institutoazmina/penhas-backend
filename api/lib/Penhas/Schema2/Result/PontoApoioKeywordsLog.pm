#<<<
use utf8;
package Penhas::Schema2::Result::PontoApoioKeywordsLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("ponto_apoio_keywords_log");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ponto_apoio_keywords_log_id_seq",
  },
  "created_on",
  { data_type => "timestamp", is_nullable => 1 },
  "cliente_id",
  { data_type => "integer", is_nullable => 1 },
  "keywords",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-07-03 16:07:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tl4bQDMtiXHTLfA1ORtdSw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
