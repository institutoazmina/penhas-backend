#<<<
use utf8;
package Penhas::Schema2::Result::AdminClientesSegment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("admin_clientes_segments");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "admin_clientes_segments_id_seq",
  },
  "status",
  {
    data_type => "varchar",
    default_value => "draft",
    is_nullable => 0,
    size => 20,
  },
  "created_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_on",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "is_test",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "label",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "last_count",
  { data_type => "bigint", is_nullable => 1 },
  "last_run_at",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "cond",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
  "attr",
  { data_type => "json", default_value => "{}", is_nullable => 0 },
  "sort",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "owner",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "modified_by",
  { data_type => "uuid", is_nullable => 1, size => 16 },
);
__PACKAGE__->set_primary_key("id");
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-05-24 16:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IdNqTw9rd6ygp7ZvL2BMQQ
use JSON;

sub apply_to_rs {
    my ($self, $c, $rs) = @_;

    my ($cond, $attr) = (from_json($self->cond), from_json($self->attr));
    $c->reply_invalid_param('$segment.cond precisa ser um hash') unless ref $cond eq 'HASH';
    $c->reply_invalid_param('$segment.attr precisa ser um hash') unless ref $attr eq 'HASH';

    # n pode usar esses
    delete $attr->{$_} for qw/columns offset rows result_class/;
    $cond->{'me.status'} = 'active' unless exists $cond->{'me.status'};
    return $rs->search($cond, $attr);
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
