package Penhas::Controller::ResetPassword;
use Mojo::Base 'Penhas::Controller';
use utf8;

use DateTime;
use Digest::SHA qw/sha256_hex/;
use Penhas::Logger;
use Penhas::Utils qw/random_string random_string_from check_password_or_die/;
use JSON;
use MooseX::Types::Email qw/EmailAddress/;
use DateTime::Format::Pg;

my $max_errors_in_24h = $ENV{MAX_CPF_ERRORS_IN_24H} || 20;
my $digits            = 6;

sub request_new {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    $c->validate_request_params(
        email       => {max_length => 200, required => 1, type => EmailAddress},
        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );
    my $email = lc(delete $params->{email});

    # limite de requests por segundo no IP
    # no maximo 5 request por hora
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(5, 60 * 60);

    # procura o cliente pelo email
    my $schema = $c->schema;
    my $found = $c->schema2->resultset('Cliente')->search({'email' => $email}, {columns => ['id', 'cpf_prefix']})->next;
    if (!$found) {
        die {
            error   => 'email_not_found',
            message => 'Não foi encontrado nenhuma conta com esse endereço de e-mail.',
            field   => 'email',
            reason  => 'invalid',
        };
    }
    my $directus_id = $found->id;

    # valido por 1 hora
    my $ttl_seconds = 60 * 60;

    my $min_ttl_retry = int($ttl_seconds * -0.94);

    # contar se ja existe um envio recente para o mesmo email
    # se restar pelo menos 6% do tempo restante, nao envia outro email
    my $item = $c->schema2->resultset('ClientesResetPassword')->search(
        {
            'created_at' => {'>' => DateTime->now->add(seconds => $min_ttl_retry)->datetime(' ')},
            'cliente_id' => $directus_id,
        }
    )->next;
    if ($item) {
        my $valid_until = $item->valid_until;

        return $c->render(
            json => {
                    message => 'Aguardando código com '
                  . $digits
                  . ' números, que enviamos o para o seu e-mail recentemente',
                ttl           => $valid_until - time(),
                min_ttl_retry => $min_ttl_retry + $ttl_seconds,
                digits        => $digits
            },
            status => 200,
        );
    }

    $item = $c->schema2->resultset('ClientesResetPassword')->create(
        {
            created_at             => DateTime->now->datetime(' '),
            requested_by_remote_ip => $remote_ip,
            cliente_id             => $directus_id,
            token                  => random_string_from('012345678', $digits),
            valid_until            => DateTime->now->add(seconds => $ttl_seconds)->datetime(' '),
        }
    );
    die 'clientes_reset_password id missing' unless $item->id;

    my $email_db = $c->schema->resultset('EmaildbQueue')->create(
        {
            config_id => 1,
            template  => 'forgot_password.html',
            to        => $email,
            subject   => 'PenhaS - Recuperação de senha',
            variables => encode_json(
                {
                    nome_completo => $found->{nome_completo},
                    code          => $item->token,
                    remote_ip     => $remote_ip,
                    app_version   => $params->{app_version},
                    email         => $email,
                    cpf           => substr($found->cpf_prefix, 0, 3)
                }
            ),
        }
    );
    die 'missing id' unless $email_db;

    $c->render(
        json => {
            message       => 'Enviamos um código com ' . $digits . ' números para o seu e-mail',
            ttl           => $ttl_seconds,
            digits        => $digits,
            min_ttl_retry => $min_ttl_retry + $ttl_seconds,
        },
        status => 200,
    );
}

sub write_new {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    $c->validate_request_params(
        email => {max_length => 200, required => 1, type => EmailAddress},
        token => {max_length => 100, required => 1, type => 'Str', min_length => $digits},
        dry => {required => 1, type => 'Int'},
    );
    my $token = delete $params->{token};
    my $dry   = delete $params->{dry};
    if (!$dry) {
        $c->validate_request_params(
            senha => {max_length => 200, required => 1, type => 'Str', min_length => 8},
        );
        check_password_or_die($params->{senha});
    }
    my $email = lc(delete $params->{email});

    # limite de requests por segundo no IP
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));

    # no maximo 30 testes por hora
    $c->apply_request_per_second_limit(30, 60 * 60);

    # procura o cliente pelo email
    my $schema = $c->schema;
    my $found  = $c->schema2->resultset('Cliente')->search({'email' => $email})->next;
    if (!$found) {
        goto INVALID_TOKEN;
    }
    my $directus_id = $found->id;

    my $item = $c->schema2->resultset('ClientesResetPassword')->search(
        {
            'valid_until' => {'>=' => DateTime->now->datetime(' ')},
            'cliente_id'  => $directus_id,
            'token'       => $token,
            'used_at'     => undef,
        }
    )->next;

    if ($item && $dry) {

        return $c->render(
            json   => {continue => 1},
            status => 200,
        );
    }
    elsif ($item) {

        $c->schema2->txn_do(
            sub {
                $item->update(
                    {
                        'used_at'           => DateTime->now->datetime(' '),
                        'used_by_remote_ip' => $remote_ip,
                    }
                );

                $item->cliente->update(
                    {
                        senha_sha256 => sha256_hex($params->{senha}),
                    }
                );
            }
        );
        return $c->render(
            json   => {success => 1},
            status => 200,
        );
    }

  INVALID_TOKEN:
    die {
        error   => 'invalid_token',
        message => 'Número não confere.',
        field   => 'token',
        reason  => 'invalid'
    };
}


1;
