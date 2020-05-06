package Penhas::Controller::SignUp;
use Mojo::Base 'Penhas::Controller';
use utf8;

use DateTime;
use Digest::SHA qw/sha256_hex/;
use Penhas::Logger;
use Penhas::Utils qw/random_string random_string_from is_test/;

use Penhas::Types qw/CEP CPF DateStr Genero Nome Raca/;
use MooseX::Types::Email qw/EmailAddress/;
use Text::Unaccent::PurePerl qw(unac_string);

my $max_errors_in_24h = $ENV{MAX_CPF_ERRORS_IN_24H} || 20;

sub post {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        dry => {required => 1, type => 'Int'},
    );
    my $dry = $params->{dry};

    $c->validate_request_params(
        nome_completo => {max_length => 200, required => 1, type => Nome, min_length => 5},
        dt_nasc       => {required   => 1,   type     => DateStr},
        cpf           => {required   => 1,   type     => CPF},
        cep           => {required   => 1,   type     => CEP},

        app_version => {max_length => 200, required => 1, type => 'Str', min_length => 1},
    );
    if (!$dry) {
        $c->validate_request_params(
            email       => {max_length => 200, required => 1, type => EmailAddress},
            genero      => {required   => 1,   type     => Genero},
            nome_social => {required   => 0,   type     => Nome},
            raca        => {required   => 1,   type     => Raca},
            apelido     => {max_length => 40,  required => 1, type => 'Str', min_length => 2},
            senha       => {max_length => 200, required => 1, type => 'Str', min_length => 6},
        );

        # nome_social quando o genero é trans ou Outro
        if ($params->{genero} =~ /trans|outro/i) {
            $c->validate_request_params(
                nome_social => {required => 1, type => 'Str'},
            );
        }else{
            $params->{nome_social} = '';
        }
    }

    $params->{cpf} =~ s/[^\d]//ga;
    $params->{cep} =~ s/[^\d]//ga;

    my $cep   = delete $params->{cep};
    my $cpf   = delete $params->{cpf};
    my $email = $dry ? undef : lc(delete $params->{email});

    # limite de requests por segundo no IP
    # no maximo 3 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(3, 60);

    # email deve ser unico
    my $schema = $c->schema;
    my $found = $email ? $c->directus->search_one(table => 'clientes', form => {'filter[email][eq]' => $email}) : undef;
    if ($found) {
        die {
            error => 'email_already_exists',
            message =>
              'E-mail já possui uma conta. Por favor, faça o o login, ou utilize a função "Esqueci minha senha".',
            field  => 'email',
            reason => 'duplicate'
        } if $found->{status} ne 'setup';

        my $directus_id = $found->{id};

        log_info("Email $email [directus id $directus_id] ja tem uma conta com status=setup...");
        my $exists = $schema->resultset('User')->search({'me.email' => $email})->next();

        # se encontrou no banco, e tambem ja tem no mastodon
        # mas o status == setup entao tivemos um problema, precisa resolver manualmente
        die {
            error   => 'email_already_exists',
            message => 'Conta com problema de sincronização. Entre em contato com o suporte.',
            field   => 'email',
            reason  => 'duplicate'
        } if $exists;

        log_info("Email $email nao tem existe no mastodon... apagando registro no Directus e continuando");

        # se nao existe, entao podemos apagar e criar uma nova
        $c->directus->delete(table => 'clientes', id => $directus_id);
    }

    # banir temporariamente quem tentar varias vezes com cpf invalido
    if ($c->directus->sum_cpf_errors(remote_ip => $remote_ip) > $max_errors_in_24h) {
        die {
            error   => 'too_many_requests',
            message => 'Você fez muitos acessos recentemente. Aguarde e tente novamente.',
            status  => 429,
        };
    }

    # pesquisa pelo CPF, pode gerar custo
    my $cpf_info = $c->cpf_lookup(cpf => $cpf, dt_nasc => $params->{dt_nasc});

    # a data nao confere...
    if ($cpf_info->dt_nasc->ymd() ne $params->{dt_nasc}) {
        &_inc_cpf_invalid_count($c, $cpf_info->cpf, $remote_ip);

        die {
            error   => 'cpf_not_match',
            message => 'A data de nascimento não confere com o titular do CPF.',
            field   => 'dt_nasc',
            reason  => 'invalid',
        };
    }

    my $nome_cpf     = uc(unac_string($cpf_info->nome));
    my $nome_titular = uc(unac_string($params->{nome_completo}));

    if ($nome_cpf ne $nome_titular) {
        &_inc_cpf_invalid_count($c, $cpf_info->cpf, $remote_ip);

        slog_error("nome fornecido != nome_cpf %s vs %s" , $nome_titular, $nome_cpf);

        die {
            error   => 'name_not_match',
            message => sprintf('O nome informado (%s) não confere com o titular do CPF. Preencha exatamente como está no documento.', $nome_titular),
            field   => 'nome_completo',
            reason  => 'invalid',
        };
    }

    # TODO
    # poderia verificar se o genero bate, mas nao tem isso no retorno por enquanto

    # cpf ja existe
    my $cpf_hash = sha256_hex($cpf);

    $found = $c->directus->search_one(table => 'clientes', form => {'filter[cpf_hash][eq]' => $cpf_hash});
    if ($found) {
        die {
            error => 'cpf_already_exists',
            message =>
              'Este CPF já possui uma conta. Entre em contato com o suporte caso não lembre do e-mail utilizado.',
            field  => 'cpf',
            reason => 'duplicate'
        };
    }

    if ($dry) {
        return $c->render(
            json   => {continue => 1},
            status => 200,
        );
    }

    my $row = $c->directus->create(
        table => 'clientes',
        form  => {
            email         => $email,
            nome_completo => $params->{nome_completo},    # deixa do jeito que o usuario digitou
            cpf_hash      => $cpf_hash,
            dt_nasc       => $cpf_info->dt_nasc->ymd(),
            cpf_prefix    => substr($cpf, 0, 4),
            cep           => $cep,

            senha_sha256 => sha256_hex($params->{senha}),

            (map { $_ => $params->{$_} || '' } qw/genero apelido raca nome_social/),
        }
    );
    my $directus_id = $row->{data}{id};
    die '$directus_id not defined' unless $directus_id;

    my $exists = $schema->resultset('User')->search({'me.email' => $email})->next();
    die {
        error   => 'email_already_exists',
        message => 'Conta com problema de sincronização. E-mail já existe no mastodon.',
        field   => 'email',
        reason  => 'duplicate'
    } if $exists;

    my $oauth2token;
    $schema->txn_do(
        sub {
            my $loop_times = 0;
            my @parts      = grep { length > 2 } split / /, $params->{nome_completo};
            my $handle     = substr($parts[0], 0, 2) . substr($parts[-1], 0, 2);

          AGAIN:
            my $free_username = $handle . random_string_from('1234567890', ++$loop_times > 10 ? 5 : 3);
            goto AGAIN if $schema->resultset('Account')->search({'me.username' => $free_username})->count();

            my $acc = $schema->resultset('Account')->create(
                {
                    'username'     => $free_username,
                    'discoverable' => '0',                             # nao aparecer na busca
                    'actor_type'   => 'Person',
                    'locked'       => '1',                             # precisa aprovar pra seguir
                    private_key    => '',
                    public_key     => '',
                    created_at     => \'now()',
                    updated_at     => \'now()',
                    note           => 'directus-id:' . $directus_id,
                    (
                        ($params->{genero} eq 'Feminimo')
                        ? (
                            display_name => '(aguardando quiz)',
                            suspended_at => undef
                          )
                        : (
                            display_name => $params->{nome_completo},
                            suspended_at => \'now()'
                        )
                    ),

                }
            );

            my $user = $acc->users->create(
                {
                    created_at => \'now()',
                    updated_at => \'now()',
                    email      => $email,

        # isso faz com que o mastodon de erro, mas eu acho melhor dar erro do que deixar uma fixa pra todos
        # ou deixar em branco que no momento ele da senha errada, mas poderia mudar pra começar a deixar passar o login
                    encrypted_password   => '$2a$4$NULL',
                    confirmed_at         => \'now()',
                    confirmation_sent_at => \'now()',
                    confirmation_token   => undef,
                    approved             => 'true',
                    locale               => 'pt-BR',
                }
            );

            $oauth2token = $user->oauth_access_tokens->create(
                {
                    created_at     => \'now()',
                    scopes         => 'read write follow',
                    token          => 'APP' . random_string(35),
                    application_id => 1,                           # web
                }
            );

            $c->directus->update(
                table => 'clientes',
                id    => $directus_id,
                form  => {
                    mastodon_user_id    => $user->id,
                    mastodon_account_id => $acc->id,
                    mastodon_username   => $free_username,
                    status              => 'active'
                }
            );

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
            mastodon_oauth2_id => $oauth2token->id,
            app_version        => $params->{app_version},
            created_at         => DateTime->now->datetime(' '),
        }
    );

    $c->render(
        json => {
            session => $c->encode_jwt(
                {
                    _oi => $oauth2token->id,
                    ses => $session_id,
                    typ => 'usr'
                }
            ),
            (is_test() ? (_test_only_id => $directus_id) : ()),
        },
        status => 200,
    );
}

sub _inc_cpf_invalid_count {
    my $c         = shift;
    my $cpf       = shift;
    my $remote_ip = shift;

    my $cpf_hash = sha256_hex($cpf);

    # contar quantas vezes o IP ja errou no ultimo dia
    my $item = $c->directus->search_one(
        table => 'cpf_erros',
        form  => {
            'filter[reset_at][gt]' => DateTime->now->datetime(' '),
            'filter[cpf_hash][eq]' => $cpf_hash,
        }
    );

    if (!$item) {
        $c->directus->create(
            table => 'cpf_erros',
            form  => {
                cpf_hash  => $cpf_hash,
                cpf_start => substr($cpf, 0, 4),
                remote_ip => $remote_ip,
                reset_at  => DateTime->now->add(days => 1)->datetime(' '),
                count     => 1,
            }
        );
    }
    else {
        # sobe o contador, pode acontecer de sobreescrever ja que nao tem lock
        # mas não mais do que 3x por minuto por causa do apply_request_per_second_limit
        $c->directus->update(
            table => 'cpf_erros',
            id    => $item->{id},
            form  => {
                count => $item->{count} + 1,
            }
        );

    }


}

1;
