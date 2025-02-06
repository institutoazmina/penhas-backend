package Penhas::Helpers;
use Mojo::Base -base;
use Penhas::SchemaConnected;
use Penhas::Controller;
use Penhas::Helpers::CPF;
use Penhas::Helpers::Quiz;
use Penhas::Helpers::AnonQuiz;
use Penhas::Helpers::ClienteSetSkill;
use Penhas::Helpers::Timeline;
use Penhas::Helpers::RSS;
use Penhas::Helpers::PontoApoio;
use Penhas::Helpers::Guardioes;
use Penhas::KeyValueStorage;
use Penhas::Helpers::ClienteAudio;
use Penhas::Helpers::Geolocation;
use Penhas::Helpers::GeolocationCached;
use Penhas::Helpers::Chat;
use Penhas::Helpers::ChatSupport;
use Penhas::Helpers::Notifications;
use Penhas::Helpers::WebHelpers;
use Penhas::Helpers::Cliente;
use Penhas::Helpers::Badges;

use Carp qw/croak confess/;

sub setup {
    my $c = shift;

    Penhas::Helpers::Quiz::setup($c);
    Penhas::Helpers::AnonQuiz::setup($c);
    Penhas::Helpers::Guardioes::setup($c);
    Penhas::Helpers::CPF::setup($c);
    Penhas::Helpers::Timeline::setup($c);
    Penhas::Helpers::ClienteSetSkill::setup($c);
    Penhas::Helpers::ClienteAudio::setup($c);
    Penhas::Helpers::PontoApoio::setup($c);
    Penhas::Helpers::RSS::setup($c);
    Penhas::Helpers::Geolocation::setup($c);
    Penhas::Helpers::GeolocationCached::setup($c);
    Penhas::Helpers::Chat::setup($c);
    Penhas::Helpers::ChatSupport::setup($c);
    Penhas::Helpers::Notifications::setup($c);
    Penhas::Helpers::WebHelpers::setup($c);
    Penhas::Helpers::Cliente::setup($c);
    Penhas::Helpers::Badges::setup($c);

    state $kv = Penhas::KeyValueStorage->instance;
    $c->helper(kv                        => sub {$kv});
    $c->helper(schema                    => \&Penhas::SchemaConnected::get_schema);
    $c->helper(schema2                   => \&Penhas::SchemaConnected::get_schema2);
    $c->helper(sum_cpf_errors            => \&sum_cpf_errors);
    $c->helper(rs_user_by_preference     => \&rs_user_by_preference);
    $c->helper(user_preference_is_active => \&user_preference_is_active);

    $c->helper(
        assert_user_has_module => sub {
            my $c      = shift;
            my $module = shift or confess 'missing param $module';

            my $user_obj = $c->stash('user_obj') or confess 'missing stash.user_obj';

            $c->log->info(
                "Asserting user has access to module '$module' - user modules is: " . $user_obj->access_modules_str());

            die {status => 400, error => 'missing_module', message => "Você não tem acesso ao modulo $module",}
              unless $user_obj->has_module($module);

            return;
        }
    );

    $c->helper(
        accept_html => sub {
            my $c = shift;
            return ($c->req->headers->header('accept') || '') =~ /html/ ? 1 : 0;
        }
    );

    $c->helper(
        remote_addr => sub {
            my $c = shift;

            foreach my $place (@{['cf-connecting-ip', 'x-real-ip', 'x-forwarded-for', 'tx']}) {
                if ($place eq 'cf-connecting-ip') {
                    my $ip = $c->req->headers->header('cf-connecting-ip');
                    return $ip if $ip;
                }
                elsif ($place eq 'x-real-ip') {
                    my $ip = $c->req->headers->header('X-Real-IP');
                    return $ip if $ip;
                }
                elsif ($place eq 'x-forwarded-for') {
                    my $ip = $c->req->headers->header('X-Forwarded-For');
                    return $ip if $ip;
                }
                elsif ($place eq 'tx') {
                    my $ip = $c->tx->remote_address;
                    return $ip if $ip;
                }
            }

            return;
        },
    );


    $c->helper('reply.exception' => sub { Penhas::Controller::reply_exception(@_) });
    $c->helper('reply.not_found' => sub { Penhas::Controller::reply_not_found(@_) });
    $c->helper('user_not_found'  => sub { Penhas::Controller::reply_not_found(@_, type => 'user_not_found') });

    $c->helper('reply_invalid_param' => sub { Penhas::Controller::reply_invalid_param(@_) });
}

sub sum_cpf_errors {
    my ($c, %opts) = @_;

    # contar quantas vezes o IP ja errou no ultimo dia
    my $total = $c->schema2->resultset('CpfErro')->search(
        {
            'reset_at'  => {'>' => DateTime->now->datetime(' ')},
            'remote_ip' => ($opts{remote_ip} or croak 'missing remote_ip'),
        }
    )->get_column('count')->sum()
      || 0;
    return $total;
}

=pod
create view view_user_preferences as
   SELECT
        p.name,
        c.id as cliente_id,
        coalesce(cp.value, p.initial_value) as value
    FROM preferences p
    CROSS JOIN clientes c
    LEFT JOIN clientes_preferences cp ON cp.cliente_id = c.id AND cp.preference_id = p.id;
=cut

sub rs_user_by_preference {
    my ($c, $pref_name, $pref_value, $as_hashref) = @_;

    $as_hashref ||= 1;

    my $rs = $c->schema2->resultset('ViewUserPreference')->search(
        {
            name  => $pref_name,
            value => $pref_value,
        },
        {
            columns => 'cliente_id',
            ($as_hashref ? (result_class => 'DBIx::Class::ResultClass::HashRefInflator') : ())
        }
    );
    return $rs;

}

sub user_preference_is_active {
    my ($c, $cliente_id, $preference_name) = @_;

    # se tiver resultado, deu match, entao esta ativo
    my $rs = $c->rs_user_by_preference($preference_name, '1')->search(
        {
            cliente_id => $cliente_id,
        }
    )->next;

    return defined $rs ? 1 : 0;
}

1;
