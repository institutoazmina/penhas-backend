package Penhas::Controller::ResetPassword;
use Mojo::Base 'Penhas::Controller';
use utf8;

use DateTime;
use Digest::SHA qw/sha256_hex/;
use Penhas::Logger;
use Penhas::Utils qw/random_string random_string_from/;
use JSON;
use MooseX::Types::Email qw/EmailAddress/;

my $max_errors_in_24h = $ENV{MAX_CPF_ERRORS_IN_24H} || 20;

sub request_new {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    $c->validate_request_params(
        email       => {max_length => 200, required => 1, type => EmailAddress},
        app_version => {max_length => 200, required => 1, type => 'Str', min_length => 1},
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
    my $found  = $c->directus->search_one(table => 'clientes', form => {'filter[email][eq]' => $email});
    if (!$found) {
        die {
            error   => 'email_not_found',
            message => 'Não foi encontrado nenhuma conta com esse endereço de e-mail.',
            field   => 'email',
            reason  => 'invalid',
        };
    }
    my $directus_id = $found->{id};

    my $digits = 6;

    # valido por 1 hora
    my $ttl_seconds = 60 * 60;

    # contar se ja existe um envio recente para o mesmo email
    # se restar pelo menos 6% do tempo restante, nao envia outro email
    my $item = $c->directus->search_one(
        table => 'clientes_reset_password',
        form  => {
            'filter[created_at][gt]' => DateTime->now->add(seconds => $ttl_seconds * -0.94)->datetime(' '),
            'filter[cliente_id][eq]' => $directus_id,
        }
    );
    if ($item) {
        my $valid_until = DateTime::Format::Pg->parse_datetime($item->{valid_until})->epoch;

        return $c->render(
            json => {
                    message => 'Aguardando código com '
                  . $digits
                  . ' números, que enviamos o para o seu e-mail recentemente',
                ttl    => $valid_until - time(),
                digits => $digits
            },
            status => 200,
        );
    }

    $item = $c->directus->create(
        table => 'clientes_reset_password',
        form  => {
            created_at             => DateTime->now->datetime(' '),
            requested_by_remote_ip => $remote_ip,
            cliente_id             => $directus_id,
            token                  => random_string_from('012345678', $digits),
            valid_until            => DateTime->now->add(seconds => $ttl_seconds)->datetime(' '),
        }
    );
    die 'clientes_reset_password id missing' unless $item->{data}{id};

    my $email = $c->schema->resultset('EmaildbQueue')->create(
        {
            config_id => 1,
            template  => 'forgot_password.html',
            to        => $email,
            subject   => 'Penhas - Recuperação de senha',
            variables => encode_json(
                {
                    nome_completo => $found->{nome_completo},
                    code          => $item->{data}{token},
                    remote_ip     => $remote_ip,
                    app_version   => $params->{app_version},
                    email         => $email,
                    cpf           => substr($found->{cpf_prefix}, 0, 3)
                }
            ),
        }
    );

    $c->render(
        json => {
            message => 'Enviamos um código com ' . $digits . ' números para o seu e-mail',
            ttl     => $ttl_seconds,
            digits  => $digits,
        },
        status => 200,
    );
}


1;
