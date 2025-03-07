use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;

my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;


AGAIN:
my $random_cpf           = random_cpf();
my $bad_random_cpf       = random_cpf(0);
my $valid_but_wrong_date = '89253398035';

my $random_email = 'email' . $random_cpf . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf);

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';

$ENV{MAX_CPF_ERRORS_IN_24H} = 10000;

my @other_fields = (
    raca        => 'pardo',
    apelido     => 'ca',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf_hashed  => cpf_hash_with_salt($random_cpf),
        dt_nasc     => '1994-01-31',
        nome_hashed => cpf_hash_with_salt(uc 'test name'),
        situacao    => '',
    }
);
get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf_hashed  => cpf_hash_with_salt($valid_but_wrong_date),
        dt_nasc     => '1944-10-10',
        nome_hashed => '404',
        situacao    => '404',
    }
);

do {
    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $bad_random_cpf,
            email         => $random_email,
            senha         => '1A`S345678A*',
            cep           => '03640123',
            genero        => 'Feminino',
            dt_nasc       => '1994-10-10',
            @other_fields,
        },
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'cpf')->json_is('/reason', 'invalid');


    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $valid_but_wrong_date,
            cep           => '03640123',
            dt_nasc       => '1944-10-10',
            @other_fields,
            dry => 1,
        },
    )->status_is(400)->json_is('/error', 'cpf_not_match');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'test name',
            cpf           => $random_cpf,
            cep           => '03640123',
            dt_nasc       => '1994-01-31',
            @other_fields,
            dry => 1,

        },
    )->status_is(200)->json_is('/continue', '1');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '3As344578a ',
            cep           => '03640123',
            genero        => 'Feminino',
            dt_nasc       => '1994-01-31',
            @other_fields,

        },
    )->status_is(400)->json_is('/error', 'warning_space_password');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '3As344578a',
            cep           => '03640123',
            genero        => 'Feminino',
            dt_nasc       => '1994-01-31',
            @other_fields,

        },
    )->status_is(400)->json_is('/error', 'pass_too_weak/char');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '65658895',
            cep           => '03640123',
            genero        => 'Feminino',
            dt_nasc       => '1994-01-31',
            @other_fields,

        },
    )->status_is(400)->json_is('/error', 'pass_too_weak/letter');
    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'oiuytrew',
            cep           => '03640123',
            genero        => 'Feminino',
            dt_nasc       => '1994-01-31',
            @other_fields,

        },
    )->status_is(400)->json_is('/error', 'pass_too_weak/number');
    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'iuy123*',
            cep           => '03640123',
            genero        => 'Feminino',
            dt_nasc       => '1994-01-31',
            @other_fields,

        },
    )->status_is(400)->json_is('/error', 'pass_too_weak/size');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'aas asdas',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'atenção1',
            cep           => '03640123',
            genero        => 'Feminino',
            dt_nasc       => '1994-01-31',
            @other_fields,

        },
    )->status_is(400)->json_is('/error', 'name_not_match');

    $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'test name',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'atenção1',
            cep           => '03640123',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero => 'MulherTrans',
        },
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'nome_social')
      ->json_is('/reason', 'is_required');
};

my $cliente_id;
my $user_obj;
do {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => 'test name',
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => '1A`S345678A*',
            cep           => '03640123',
            dt_nasc       => '1994-01-31',
            nome_social   => 'foobar lorem',
            @other_fields,
            genero => 'MulherTrans',

        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    $user_obj   = get_schema2->resultset('Cliente')->find($cliente_id);

    my $cadastro = $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(200)->tx->res->json;

    is $cadastro->{user_profile}{nome_completo}, 'test name';
    is $cadastro->{user_profile}{nome_social},   'foobar lorem';

    is $user_obj->clientes_preferences->count, 0, 'no clientes_preferences';
    $t->get_ok('/me/preferences', {'x-api-key' => $res->{session}})->status_is(200);
    ok my $key0 = last_tx_json->{preferences}[0]{key}, 'has some pref';
    ok my $key1 = last_tx_json->{preferences}[1]{key}, 'has some pref';
    ok my $key2 = last_tx_json->{preferences}[2]{key}, 'has some pref';

    $t->post_ok(
        '/me/preferences', {'x-api-key' => $res->{session}},
        form => {
            ignored => '1',
            $key0   => 0,
            $key1   => 1,
        }
    )->status_is(204);
    $t->get_ok('/me/preferences', {'x-api-key' => $res->{session}})->status_is(200);
    is last_tx_json->{preferences}[0]{key}, $key0, 'name ok';
    is last_tx_json->{preferences}[0]{value}, 0, 'key 0 is updated to 0';

    is last_tx_json->{preferences}[1]{value}, 1, 'key 1 is still 1';
    is last_tx_json->{preferences}[1]{key}, $key1, 'name ok';
    is $user_obj->clientes_preferences->count, 2, '2 clientes_preferences';

    $t->post_ok(
        '/me/preferences', {'x-api-key' => $res->{session}},
        form => {
            $key0 => 1,
            $key2 => 0,
        }
    )->status_is(204);
    $t->get_ok('/me/preferences', {'x-api-key' => $res->{session}})->status_is(200);
    is last_tx_json->{preferences}[0]{key}, $key0, 'name ok';
    is last_tx_json->{preferences}[0]{value}, 1, 'key 0 is updated to 1';

    is last_tx_json->{preferences}[2]{value}, 0, 'key 1 is updated to 0';
    is last_tx_json->{preferences}[2]{key}, $key2, 'name ok';

    is $user_obj->clientes_preferences->count, 3, '3 clientes_preferences';

    $t->post_ok(
        '/logout',
        {'x-api-key' => $res->{session}}
    )->status_is(204);

    $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(403);
};

on_scope_exit { user_cleanup(user_id => $cliente_id); };

my $session;
subtest_buffered 'Login' => sub {
    $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => '1AS34567',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(400)->json_is('/error', 'wrongpassword_tooweak');

    my $res = $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => '1A`S345678A*',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(200)->json_has('/session')->tx->res->json;

    $session = $res->{session};
    $t->get_ok(
        '/me',
        {'x-api-key' => $res->{session}}
    )->status_is(200);

};

my $directus = get_cliente_by_email($random_email);
subtest_buffered 'Contador ligacao policia' => sub {

    is $directus->{qtde_ligar_para_policia}, 0, 'qtde_ligar_para_policia is 0';
    $t->post_ok(
        '/me/call-police-pressed',
        {'x-api-key' => $session}
    )->status_is(204);

    $directus = get_cliente_by_email($random_email);
    is $directus->{qtde_ligar_para_policia}, 1, 'qtde_ligar_para_policia increased';
};

subtest_buffered 'Contador login offline' => sub {

    is $directus->{qtde_login_offline}, 0, 'qtde_login_offline is 0';
    $t->post_ok(
        '/me/inc-login-offline',
        {'x-api-key' => $session},
        form => {inc_by => 3}
    )->status_is(204);

    $directus = get_cliente_by_email($random_email);
    is $directus->{qtde_login_offline}, 3, 'qtde_login_offline increased';
};


subtest_buffered 'Modos' => sub {

    $t->post_ok(
        '/me/modo-anonimo-toggle',
        {'x-api-key' => $session},
        form => {active => 1}
    )->status_is(204);

    $directus = get_cliente_by_email($random_email);
    is $directus->{modo_anonimo_ativo},   1, 'modo_anonimo_ativo 1';
    is $directus->{modo_camuflado_ativo}, 0, 'modo_camuflado_ativo 0';

    $t->post_ok(
        '/me/modo-camuflado-toggle',
        {'x-api-key' => $session},
        form => {active => 1}
    )->status_is(204);

    $directus = get_cliente_by_email($random_email);
    is $directus->{modo_anonimo_ativo},   1, 'modo_anonimo_ativo 1';
    is $directus->{modo_camuflado_ativo}, 1, 'modo_camuflado_ativo 1';

    $t->post_ok(
        '/me/modo-anonimo-toggle',
        {'x-api-key' => $session},
        form => {active => 0}
    )->status_is(204);

    $directus = get_cliente_by_email($random_email);
    is $directus->{modo_anonimo_ativo}, 0, 'modo_anonimo_ativo 0';

    $t->post_ok(
        '/me/modo-camuflado-toggle',
        {'x-api-key' => $session},
        form => {active => 0}
    )->status_is(204);

    $t->post_ok(
        '/me/ja-foi-vitima-de-violencia-toggle',
        {'x-api-key' => $session},
        form => {active => 1}
    )->status_is(204);

    $directus = get_cliente_by_email($random_email);
    is $directus->{modo_anonimo_ativo},         0, 'modo_anonimo_ativo 0';
    is $directus->{modo_camuflado_ativo},       0, 'modo_camuflado_ativo 0';
    is $directus->{ja_foi_vitima_de_violencia}, 1, 'ja_foi_vitima_de_violencia 1';

};

subtest_buffered 'update' => sub {
    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            email => $random_email,
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha_atual');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha => $random_email,
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha_atual')
      ->json_is('/reason', 'is_required');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => 'foobar',
            senha       => $random_email,
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha_atual')
      ->json_is('/reason', 'invalid');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {senha_atual => 'foobar', senha => 'lalalala'}
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha_atual')
      ->json_is('/reason', 'invalid');

    my $random_user = get_schema2->resultset('Cliente')->search({email => {'!=' => $random_email}})->next;
    if ($random_user) {
        $t->put_ok(
            '/me',
            {'x-api-key' => $session},
            form => {
                senha_atual => '1A`S345678A*',
                email       => $random_user->email,
            }
        )->status_is(400, 'xp')->json_is('/error', 'form_error')->json_is('/field', 'email')
          ->json_is('/reason', 'duplicate');

    }

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => '1A`S345678A*',
            senha       => '1234578',
        }
    )->status_is(400, 'senha muito fraca')->json_is('/error', 'pass_too_weak');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => '1A`S345678A*',
            senha       => 'XXD~EFWDA1',
        }
    )->status_is(200, 'senha atualizada');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {}
    )->status_is(200, 'just messing arround');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {skills => '12225'}
      )->status_is(400)->json_is('/error', 'form_error')    #
      ->json_is('/field',  'skills')                        #
      ->json_is('/reason', 'invalid')                       #
      ->json_like('/message', qr/12225/);

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => 'XXD~EFWDA1',
            email       => $random_email,
        }
    )->status_is(200);

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {apelido => 'ze pequenoあ'}
    )->status_is(200)->json_is('/user_profile/apelido', 'ze pequenoあ', 'nome ok, encoding ok');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            minibio => 'sora wo',
            raca    => 'amarelo',
        }
      )->status_is(200)    #
      ->json_is('/user_profile/minibio', 'sora wo', 'minibio ok')    #
      ->json_is('/user_profile/raca',    'amarelo', 'raca ok');

    my @rand_skills
      = map { $_->id() } get_schema2->resultset('Skill')             #
      ->search(undef, {rows => 1 + int(rand() * 3), order_by => \'random()'})->all;

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {skills => join ',', @rand_skills}
    )->status_is(200)->json_is('/user_profile/skills', [sort @rand_skills], 'skills updated');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {skills => ''}
    )->status_is(200)->json_is('/user_profile/skills', [], 'all skills removed');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {skills => join ',', @rand_skills}
    )->status_is(200)->json_is('/user_profile/skills', [sort @rand_skills], 'skills updated again');

    $t->put_ok(
        '/me',
        {'x-api-key' => $session},
        form => {skills_remove => '1'}
    )->status_is(200)->json_is('/user_profile/skills', [], 'skills updated [all skills removed]');

};

subtest_buffered 'Reset de senha' => sub {

    is(get_forget_password_row($directus->{id}), undef, 'no rows');

    $t->post_ok(
        '/reset-password/request-new',
        form => {
            email       => $random_email,
            app_version => '...',
        }
    )->status_is(200);

    ok(my $forget = get_forget_password_row($directus->{id}), 'has a new row');
    ok $forget->{token}, 'has token';
    is $forget->{used_at}, undef, 'used_at is null';

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 1,
            token       => '1A`S345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'invalid_token');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => '1A`S345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'form_error')->json_is('/field', 'senha');

    my $rand_password = 'aS3lso34o*83m2' . rand;
    $user_obj->update({senha_sha256 => sha256_hex($rand_password)});
    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => $forget->{token},
            senha       => $rand_password,
            app_version => '...',
        }
    )->status_is(400, 'not the same')->json_is('/error', 'pass_same_as_before', 'nao pode ser igual');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 1,
            token       => $forget->{token},
            senha       => 'abc1A`S345678',
            app_version => '...',
        }
    )->status_is(200, 'ok 1')->json_is('/continue', '1', 'suc 2');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => $forget->{token},
            senha       => 'abc1A`S345678',
            app_version => '...',
        }
    )->status_is(200, 'ok 2')->json_is('/success', '1', 'suc 2');

    $t->post_ok(
        '/reset-password/write-new',
        form => {
            email       => $random_email,
            dry         => 0,
            token       => $forget->{token},
            senha       => 'abc1A`S345678',
            app_version => '...',
        }
    )->status_is(400)->json_is('/error', 'invalid_token');

    ok($forget = get_forget_password_row($directus->{id}), 'has a new row');
    ok $forget->{used_at}, 'used_at is NOT null';

    my $email_rs = get_schema->resultset('EmaildbQueue')->search(
        {
            to => $random_email,
        }
    );

    $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => 'abc1A`S345678',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(200, 'pass ok')->json_has('/session');
    is $user_obj->status, 'active', 'status active';
    my $session = last_tx_json()->{session};
    $t->get_ok(
        '/me/delete-text',
        {'x-api-key' => $session},
    )->status_is(200)->json_has('/text', 'tem texto');
    $t->delete_ok(
        '/me',
        {'x-api-key' => $session},
        form => {
            senha_atual => 'abc1A`S345678',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(204);
    is $user_obj->discard_changes->status, 'deleted_scheduled', 'in deletion';
    ok $user_obj->perform_delete_at, 'perform_delete_at is not null';

    is $email_rs->search({template => 'account_deletion.html'})->count, 1, 'ok';
    $t->get_ok('/me', {'x-api-key' => $session})->status_is(403);


    $t->post_ok(
        '/login',
        form => {
            email       => $random_email,
            senha       => 'abc1A`S345678',
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(200)->json_has('/session')->json_is('/deleted_scheduled', '1');
    $session = last_tx_json()->{session};
    is $user_obj->discard_changes->status, 'deleted_scheduled', 'still in deletion';
    ok $user_obj->perform_delete_at, 'perform_delete_at still not null';
    $t->get_ok('/me', {'x-api-key' => $session})->status_is(404);

    $t->post_ok(
        '/reactivate',
        {'x-api-key' => $session},
        form => {
            app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        }
    )->status_is(204);
    $t->get_ok('/me', {'x-api-key' => $session})->status_is(200);

    is $user_obj->discard_changes->status, 'active', 'is active';
    is $user_obj->perform_delete_at, undef, 'perform_delete_at is null';

    is $email_rs->search({template => 'account_reactivate.html'})->count, 1, 'ok';

};

done_testing();

exit;
