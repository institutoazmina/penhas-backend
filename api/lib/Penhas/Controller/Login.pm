package Penhas::Controller::Login;
use Mojo::Base 'Penhas::Controller';
use utf8;

use DateTime;
use Digest::SHA qw/sha256_hex/;
use Digest::MD5 qw/md5_hex/;
use Penhas::Logger;
use Penhas::Utils qw/random_string is_test/;
use MooseX::Types::Email qw/EmailAddress/;

use DateTime::Format::Pg;

my $max_email_errors_before_lock   = $ENV{MAX_EMAIL_ERRORS_BEFORE_LOCK}   || 15;
my $wait_seconds_to_account_unlock = $ENV{WAIT_SECONDS_TO_ACCOUNT_UNLOCK} || 86400;

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        email       => {max_length => 200, required => 1, type => EmailAddress},
        senha       => {max_length => 200, required => 1, type => 'Str'},
        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );
    my $email      = lc(delete $params->{email});
    my $senha_crua = delete $params->{senha};

    eval { check_password_or_die($senha_crua) };
    if (length($senha_crua) < 8 || $@) {
        die {
            error   => 200,
            message => 'Sua senha é fraca. Por favor, clique no botão "Esqueci minha senha" para resetar.',
            field   => 'password',
            reason  => 'invalid'
        };
    }

    my $senha     = sha256_hex($senha_crua);
    my $senha_md5 = md5_hex($senha_crua);

    # limite de requests por segundo no IP
    # no maximo 3 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => 'login' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(3, 60);

    # procura pelo email
    my $schema    = $c->schema;
    my $found_obj = $c->schema2->resultset('Cliente')->search(
        {email => $email, status => {in => ['deleted_scheduled', 'active', 'banned']}},
    )->next;
    my $found         = $found_obj ? {$found_obj->get_columns()} : undef;
    my $error_code    = 'notfound';
    my $error_message = 'Você ainda não possui cadastro conosco.';

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
                $found_obj->update(
                    {
                        login_status                 => 'OK',
                        login_status_last_blocked_at => ''
                    }
                );
            }

        }
        elsif ($found->{login_status} eq 'BLOCK') {
            die {
                error   => 'login_status_block',
                message => 'Logon para este e-mail está suspenso interminavelmente.',
            };
        }

        # confere a senha
        if (lc($senha) eq lc($found->{senha_sha256})) {
            goto LOGON;
        }
        elsif (lc($senha_md5) eq lc($found->{senha_sha256})) {
            $found_obj->update({senha_sha256 => $senha});
            goto LOGON;
        }
        else {
            my $total_errors = 1 + $c->schema2->sum_login_errors(cliente_id => $directus_id);
            my $now          = DateTime->now->datetime(' ');
            $c->schema2->resultset('LoginErro')->create(
                {
                    cliente_id => $directus_id,
                    remote_ip  => $remote_ip,
                    created_at => $now,
                }
            );

            if ($total_errors >= $max_email_errors_before_lock) {
                $found_obj->update(
                    {
                        login_status                 => 'NOK',
                        login_status_last_blocked_at => $now,
                    }
                );
            }
            $error_code    = 'wrongpassword';
            $error_message = 'E-mail ou senha inválida.';
            goto WRONG_PASS;
        }
    }

  WRONG_PASS:

    die {
        error   => $error_code,
        message => $error_message,
        field   => 'password',
        reason  => 'invalid'
    };

  LOGON:
    my $directus_id       = $found->{id};
    my $deleted_scheduled = 0;

    # acertou a senha, mas esta suspenso
    if ($found->{status} ne 'active') {
        if ($found->{status} eq 'deleted_scheduled') {
            $deleted_scheduled++;
        }
        else {
            die {
                error   => 'ban',
                message => 'A conta suspensa.',
                field   => 'email',
                reason  => 'invalid'
            };
        }
    }

    $found_obj->update({qtde_login_senha_normal => \'qtde_login_senha_normal + 1'});

    # invalida todas as outras sessions
    if ($ENV{DELETE_PREVIOUS_SESSIONS}) {
        $c->schema2->resultset('ClientesActiveSession')->search(
            {cliente_id => $directus_id},
        )->delete;
    }

    my $session = $c->schema2->resultset('ClientesActiveSession')->create(
        {cliente_id => $directus_id},
    );
    my $session_id = $session->id;

    $c->schema2->resultset('LoginLog')->create(
        {
            remote_ip   => $remote_ip,
            cliente_id  => $directus_id,
            app_version => $params->{app_version},
            created_at  => DateTime->now->datetime(' '),
        }
    );

    # marca que o usuário esta fazendo um login, pra ser usado no GET /me pra ignorar o quiz
    my $key = $ENV{REDIS_NS} . 'is_during_login:' . $directus_id;
    $c->kv->redis->setex($key, 120, '1');

    $c->render(
        json => {
            (
                $deleted_scheduled
                ? (
                    deleted_scheduled => 1,
                  )
                : ()
            ),
            session => $c->encode_jwt(
                {
                    ses => $session_id,
                    typ => 'usr'
                }
            ),
            (is_test() ? (_test_only_id => $directus_id) : ()),
        },
        status => 200,
    );
}

1;
