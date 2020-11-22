#<<<
use utf8;
package Penhas::Schema2::Result::FaqTelaSobreCategoria;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("faq_tela_sobre_categoria");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "sort",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "owner",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "modified_by",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "modified_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "is_test",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "faq_tela_sobres",
  "Penhas::Schema2::Result::FaqTelaSobre",
  { "foreign.fts_categoria_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-11-22 16:46:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LHwiAZLXawx3RtrtnooWEw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
