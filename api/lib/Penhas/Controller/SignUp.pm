package Penhas::Controller::SignUp;
use Mojo::Base 'Penhas::Controller';
use utf8;
use Scope::OnExit;

use DateTime;
use Digest::SHA qw/sha256_hex/;
use Penhas::Logger;
use Penhas::Utils qw/random_string random_string_from is_test cpf_hash_with_salt check_password_or_die/;
use Scope::OnExit;
use Convert::Z85;
use Crypt::PRNG qw(random_bytes);
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

        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );
    if (!$dry) {
        $c->validate_request_params(
            email       => {max_length => 200, required => 1, type => EmailAddress},
            genero      => {required   => 1,   type     => Genero},
            nome_social => {required   => 0,   type     => Nome},
            raca        => {required   => 1,   type     => Raca},
            apelido     => {max_length => 40,  required => 1, type => 'Str', min_length => 2},
            senha       => {max_length => 200, required => 1, type => 'Str'},
        );

        # nome_social quando o genero é trans ou Outro
        if ($params->{genero} =~ /trans|outro/i) {
            $c->validate_request_params(
                nome_social => {required => 1, type => 'Str'},
            );

            $c->validate_request_params(
                genero_outro => {required => 1, type => 'Str', max_length => 200},
            ) if $params->{genero} eq 'Outro';
        }

        else {
            $params->{nome_social} = '';
        }

        check_password_or_die($params->{senha});
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

    my $lock = "email:$email";
    $c->kv()->lock_and_wait($lock);
    on_scope_exit { $c->kv()->unlock($lock) };

    # email deve ser unico
    my $schema = $c->schema;
    my $found  = $email ? $c->schema2->resultset('Cliente')->search({email => $email})->next : undef;
    if ($found) {
        die {
            error => 'email_already_exists',
            message =>
              'E-mail já possui uma conta. Por favor, faça o o login, ou utilize a função "Esqueci minha senha".',
            field  => 'email',
            reason => 'duplicate'
        };
    }

    # banir temporariamente quem tentar varias vezes com cpf invalido
    if ($c->sum_cpf_errors(remote_ip => $remote_ip) > $max_errors_in_24h) {
        die {
            error   => 'too_many_requests',
            message => 'Você fez muitos acessos recentemente. Aguarde e tente novamente.',
            status  => 429,
        };
    }

    # pesquisa pelo CPF, pode gerar custo
    my $cpf_info = $c->cpf_lookup(cpf => $cpf, dt_nasc => $params->{dt_nasc});

    # a data nao confere...
    if ($cpf_info->nome_hashed eq '404' || $cpf_info->dt_nasc->ymd() ne $params->{dt_nasc}) {
        &_inc_cpf_invalid_count($c, $cpf, $remote_ip);

        die {
            error   => 'cpf_not_match',
            message => 'Data de nascimento não confere com o CPF.',
            field   => 'dt_nasc',
            reason  => 'invalid',
        };
    }

    my $nome_titular        = uc(unac_string($params->{nome_completo}));
    my $nome_titular_hashed = cpf_hash_with_salt($nome_titular);

    if ($cpf_info->nome_hashed ne $nome_titular_hashed) {
        &_inc_cpf_invalid_count($c, $cpf, $remote_ip);

        slog_error(
            "nome fornecido != nome_cpf %s %s vs %s", $nome_titular, $nome_titular_hashed,
            $cpf_info->nome_hashed
        );

        die {
            error   => 'name_not_match',
            message => 'Nome deve ser escrito igual ao do seu CPF.',
            field   => 'nome_completo',
            reason  => 'invalid',
        };
    }

    # TODO
    # poderia verificar se o genero bate, mas nao tem isso no retorno por enquanto

    my $lock2 = "cpf:$cpf";
    $c->kv()->lock_and_wait($lock2);
    on_scope_exit { $c->kv()->unlock($lock2) };

    # cpf ja existe
    my $cpf_hash = sha256_hex($cpf);
    $found = $c->schema2->resultset('Cliente')->search({cpf_hash => $cpf_hash})->next;
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

    my $row = $c->schema2->resultset('Cliente')->create(
        {
            email         => $email,
            nome_completo => $params->{nome_completo},    # deixa do jeito que o usuario digitou
            cpf_hash      => $cpf_hash,
            dt_nasc       => $cpf_info->dt_nasc->ymd(),
            cpf_prefix    => substr($cpf, 0, 4),
            cep           => $cep,

            senha_sha256 => sha256_hex($params->{senha}),

            (map { $_ => $params->{$_} || '' } qw/genero apelido raca nome_social genero_outro/),
            status        => 'active',
            created_on    => \'NOW()',
            salt_key      => encode_z85(random_bytes(8)),    # 8 bytes, que viram 10 chars em base85
            skills_cached => '[]',
        }
    );
    my $directus_id = $row->id;
    die '$directus_id not defined' unless $directus_id;

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

    $c->render(
        json => {
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

sub _inc_cpf_invalid_count {
    my $c         = shift;
    my $cpf       = shift;
    my $remote_ip = shift;

    my $cpf_hash = sha256_hex($cpf);

    my $rs = $c->schema2->resultset('CpfErro');

    # contar quantas vezes o IP ja errou no ultimo dia
    my $item = $rs->search(
        {
            'reset_at' => {'>' => DateTime->now->datetime(' ')},
            'cpf_hash' => $cpf_hash,
        }
    )->next;

    if (!$item) {
        $rs->create(
            {
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
        $item->update(
            {
                count => \'count + 1',
            }
        );

    }


}

1;
