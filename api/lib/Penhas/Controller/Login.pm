package Penhas::Controller::Login;
use Mojo::Base 'Penhas::Controller';
use utf8;

use DateTime;
use Digest::SHA qw/sha256_hex/;
use Penhas::Logger;
use Penhas::Utils qw/random_string is_test/;
use MooseX::Types::Email qw/EmailAddress/;

use DateTime::Format::Pg;

my $max_email_errors_before_lock   = $ENV{MAX_EMAIL_ERRORS_BEFORE_LOCK}   || 3;
my $wait_seconds_to_account_unlock = $ENV{WAIT_SECONDS_TO_ACCOUNT_UNLOCK} || 86400;

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        email       => {max_length => 200, required => 1, type => EmailAddress},
        senha       => {max_length => 200, required => 1, type => 'Str', min_length => 6},
        app_version => {max_length => 200, required => 1, type => 'Str', min_length => 1},
    );
    my $email = lc(delete $params->{email});
    my $senha = sha256_hex(delete $params->{senha});

    # limite de requests por segundo no IP
    # no maximo 3 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(3, 60);

    my $senha_falsa = 0;

    # procura pelo email
    my $schema = $c->schema;
    my $found  = $c->directus->search_one(table => 'clientes', form => {'filter[email][eq]' => $email});
    if ($found) {
        my $directus_id = $found->{id};
        if ($found->{login_status} eq 'NOK' && $found->{login_status_last_blocked_at}) {

            my $parsed = DateTime::Format::Pg->parse_datetime($found->{login_status_last_blocked_at});

            my $delta_secs = time() - $parsed->epoch;

            if ($delta_secs <= $wait_seconds_to_account_unlock) {
                die {
                    error   => 'login_status_nok',
                    message => 'Logon para este e-mail está suspenso temporariamente.',
                };

            }
            else {
                $c->directus->update(
                    table => 'clientes',
                    id    => $directus_id,
                    form  => {
                        login_status                 => 'OK',
                        login_status_last_blocked_at => ''
                    }
                );
            }

        }
        elsif ($found->{login_status} eq 'BLOCK') {
            die {
                error   => 'login_status_block',
                message => 'Logon para este e-mail está suspenso temporariamente.',
            };
        }

        # confere a senha
        if (lc($senha) eq lc($found->{senha_sha256})) {
            goto LOGON;
        }
        else {

            # a conta pode ter uma  senha falsa, que pode fazer login
            if ($found->{senha_falsa_sha256}) {

                if (lc($senha) eq lc($found->{senha_falsa_sha256})) {
                    $senha_falsa = 1;
                    goto LOGON;
                }
            }

            my $total_errors = 1 + $c->directus->sum_login_errors(cliente_id => $directus_id);
            my $now          = DateTime->now->datetime(' ');
            $c->directus->create(
                table => 'login_erros',
                form  => {
                    cliente_id => $directus_id,
                    remote_ip  => $remote_ip,
                    created_at => $now,
                }
            );

            if ($total_errors >= $max_email_errors_before_lock) {
                $c->directus->update(
                    table => 'clientes',
                    id    => $directus_id,
                    form  => {
                        login_status                 => 'NOK',
                        login_status_last_blocked_at => $now,
                    }
                );
            }

            goto WRONG_PASS;
        }
    }

  WRONG_PASS:

    die {
        error   => 'wrongpassword',
        message => 'E-mail ou senha inválida.',
        field   => 'password',
        reason  => 'invalid'
    };

  LOGON:
    my $directus_id = $found->{id};

    # acertou a senha, mas esta suspenso
    if ($found->{status} ne 'active') {
        die {
            error   => 'ban',
            message => 'A conta suspensa.',
            field   => 'email',
            reason  => 'invalid'
        };
    }

    if ($senha_falsa) {
        $found->{qtde_login_senha_falsa}++;
    }
    else {
        $found->{qtde_login_senha_normal}++;
    }

    $c->directus->update(
        table => 'clientes',
        id    => $directus_id,
        form  => {
            qtde_login_senha_normal => $found->{qtde_login_senha_normal},
            qtde_login_senha_falsa  => $found->{qtde_login_senha_falsa},
        }
    );

     my $session = $c->directus->create(
        table => 'clientes_active_sessions',
        form  => {
            cliente_id => $directus_id,
        }
    );
    my $session_id = $session->{data}{id};
    die '$session_id not defined' unless $session_id;

    $c->directus->create(
        table => 'login_logs',
        form  => {
            remote_ip          => $remote_ip,
            cliente_id         => $directus_id,
            app_version        => $params->{app_version},
            created_at         => DateTime->now->datetime(' '),
        }
    );

    $c->render(
        json => {
            session => $c->encode_jwt(
                {
                    ses => $session_id,
                    typ => 'usr'
                }
            ),
            senha_falsa => $senha_falsa ? 1 : 0,
            (is_test() ? (_test_only_id => $directus_id) : ()),
        },
        status => 200,
    );
}

1;
