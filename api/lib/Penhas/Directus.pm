package Penhas::Directus;
use common::sense;
use MooseX::Singleton;
use JSON;
use Penhas::Logger;
use Penhas::Utils qw/exec_tx_with_retry/;
use Carp qw/croak/;
use DateTime;

has ua => (is => 'rw', isa => 'Mojo::UserAgent', lazy => 1, builder => '_build_ua');

sub directus_endpoint {
    $ENV{DIRECUTS_ENDPOINT} || 'http://0.0.0.0:8080/';
}

sub url_for {
    my $self = shift;
    return join '/', $self->directus_endpoint, 'directrus', shift();
}

sub default_headers {
    die 'Configurar DIRECUTS_API_TOKEN' unless $ENV{DIRECUTS_API_TOKEN};
    return {'Authorization' => 'bearer ' . $ENV{DIRECUTS_API_TOKEN}};
}

sub _build_ua {

    # Total limit of 15 seconds, of which 5 seconds may be spent connecting
    # 30 waiting for the response
    Mojo::UserAgent->new->connect_timeout(5)->request_timeout(15)->inactivity_timeout(30);
}

sub create {
    my ($self, %opts) = @_;

    my $collection_name = $opts{table} or croak 'missing table';

    my $tx = &exec_tx_with_retry(
        sub {
            $self->ua->post(
                $self->url_for("items/$collection_name"),
                {%{$self->default_headers()}, 'content-type' => 'application/json'},
                json => $opts{form}
            );
        }
    );
    my $res = $tx->res->json or die sprintf 'Response Body is not a json: %s', $tx->res->body;

    return $res;
}

sub update {
    my ($self, %opts) = @_;

    my $collection_name = $opts{table} or croak 'missing table';
    my $item_id         = $opts{id}    or croak 'missing id';

    my $tx = &exec_tx_with_retry(
        sub {
            $self->ua->patch(
                $self->url_for("items/$collection_name/$item_id"),
                {%{$self->default_headers()}, 'content-type' => 'application/json'},
                json => $opts{form}
            );
        }
    );

    return 1 if $tx->res->code == 204;
    my $res = $tx->res->json or die sprintf 'Response Body is not a json: %s', $tx->res->body;

    return $res;
}

sub search {
    my ($self, %opts) = @_;

    my $collection_name = $opts{table} or croak 'missing table';

    my $tx = &exec_tx_with_retry(
        sub {
            $self->ua->get(
                $self->url_for("items/$collection_name"),
                $self->default_headers(),
                form => $opts{form}
            );
        }
    );

    my $res = $tx->res->json or die sprintf 'Response Body is not a json: %s', $tx->res->body;

    return $res;
}

sub search_one {
    my $res = shift->search(@_);

    return $res->{data}[0];
}

sub sum_login_errors {
    my ($self, %opts) = @_;

    my $rows = $self->search(
        table => 'login_erros',
        form  => {
            'filter[created_at][gt]' => DateTime->now->add(minutes => -60)->datetime(' '),
            'filter[cliente_id][eq]' => ($opts{cliente_id} or croak 'missing cliente_id'),
        }
    );

    my $total = 0;
    foreach my $row (@{$rows->{data}}) {
        $total += 1;
    }

    return $total;
}

1;
