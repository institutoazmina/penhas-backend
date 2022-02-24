#<<<
use utf8;
package Penhas::Schema2::Result::Municipality;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("municipalities");
__PACKAGE__->add_columns(
  "ogc_fid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "municipalities_ogc_fid_seq",
  },
  "id",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "cd_mun",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "nm_mun",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "sigla_uf",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "area_km2",
  { data_type => "double precision", is_nullable => 1 },
  "wkb_geometry",
  { data_type => "geometry", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("ogc_fid");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-02-24 11:48:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GW7l242r5Xt354Xz0f10QA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
