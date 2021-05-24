package Penhas::Helpers::GeolocationCached;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Penhas::Utils qw/is_test trunc_to_meter/;
use Mojo::Util qw/trim/;
use Scope::OnExit;

sub setup {
    my $self = shift;

    $self->helper('reverse_geo_code_cached' => sub { &reverse_geo_code_cached(@_) });
    $self->helper('geo_code_cached'         => sub { &geo_code_cached(@_) });
}

sub geo_code_cached {
    my ($c, $address) = @_;

    $address = lc $address;
    $address = trim($address);

    return &_get_cached($c, 'geo_code', $address);
}

sub reverse_geo_code_cached {
    my ($c, $lat_lng) = @_;

    my ($lat, $lng) = split /,/, $lat_lng;

    $lat = trunc_to_meter($lat);
    $lng = trunc_to_meter($lng);

    return &_get_cached($c, 'reverse_geo_code', $lat . ',' . $lng);
}

sub _get_cached {
    my ($c, $sub, $key) = @_;

    my $lock_key = $c->kv->lock_and_wait("$sub:cache:$key");
    on_scope_exit { $c->kv->redis->del($lock_key) };

    my $cached = $c->schema2->resultset('GeoCache')->search(
        {
            key         => $key,
            valid_until => {'>=' => \'now()'},
        },
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
    )->next;
    return $cached->{value} if $cached;

    if ($c->stash('geo_code_rps_key')) {

        # max de 100 requets sem cache por dia (no ip, ou no usuario)
        $c->stash(apply_rps_on => $c->stash('geo_code_rps_key'));
        $c->apply_request_per_second_limit(100, 86400);
    }

    my $ttl    = 2592000;                # 30 dias
    my $result = $c->$sub($key) || '';
    $ttl = 3600 if !$result;             # 1 hora

    $c->schema2->resultset('GeoCache')->create(
        {
            key         => $key,
            value       => $result,
            valid_until => \"NOW()+ INTERVAL '$ttl seconds'",
            created_at  => \'NOW()'
        }
    );

    return $result;
}

1;
