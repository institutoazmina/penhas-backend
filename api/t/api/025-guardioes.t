use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;
use Penhas::Test;
use Penhas::Minion::Tasks::SendSMS;
use Penhas::Minion::Tasks::DeleteUser;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;
use DateTime;

my $schema2 = $t->app->schema2;

my $now_datetime = DateTime->now()->datetime('T') . 'Z';

AGAIN:
my $random_cpf   = random_cpf();
my $random_email = 'email' . $random_cpf . '@something.com';
goto AGAIN if cpf_already_exists($random_cpf);

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';
$ENV{SKIP_END_NEWS}            = '1';

my @other_fields = (
    raca        => 'branco',
    apelido     => 'guardioes',
    app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
    dry         => 0,
);

my $nome_completo = 'test name guards';

get_schema->resultset('CpfCache')->find_or_create(
    {
        cpf_hashed  => cpf_hash_with_salt($random_cpf),
        dt_nasc     => '1994-01-31',
        nome_hashed => cpf_hash_with_salt(uc $nome_completo),
        situacao    => '',
    }
);

my ($cliente_id, $session);
subtest_buffered 'Cadastro com sucesso' => sub {
    my $res = $t->post_ok(
        '/signup',
        form => {
            nome_completo => $nome_completo,
            cpf           => $random_cpf,
            email         => $random_email,
            senha         => 'W^1SAA3456',
            cep           => '12345678',
            dt_nasc       => '1994-01-31',
            @other_fields,
            genero => 'Feminino',

        },
    )->status_is(200)->tx->res->json;

    $cliente_id = $res->{_test_only_id};
    $session    = $res->{session};
};

on_scope_exit { user_cleanup(user_id => $cliente_id); };
my $job = Minion::Job->new(
    id     => fake_int(1, 99)->(),
    minion => $t->app->minion,
    task   => 'testmocked',
    notes  => {hello => 'mock'}
);
do {
    $ENV{GUARDS_ALLOWED_COUNTRY_CODES} = ',55,';

    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            celular => '+1 484 2918 467',
        }
    )->status_is(400)->json_is('/error', 'contry_not_allowed', 'testando bloqueio de paises');

    $ENV{GUARDS_ALLOWED_COUNTRY_CODES} = '';
    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            celular => '11 81144666',
        }
    )->status_is(400)->json_is('/error', 'parser_error', 'numero nao existe no brasil')->json_is('/field', 'celular')
      ->json_is('/reason', 'invalid');

    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            celular => '11 31144666',
        }
    )->status_is(400)->json_is('/error', 'number_is_not_mobile', 'numero nao eh celular')
      ->json_is('/field', 'celular')->json_is('/reason', 'invalid');


    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'test nome',
            celular => '+14842918467',
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '+1 484-291-8467')
      ->json_is('/data/nome',        'test nome')->json_is('/data/is_pending', '1')->json_is('/data/is_expired', '0')
      ->json_is('/data/is_accepted', '0')->json_like('/message', qr/Enviamos um SMS/);

    trace_popall;
    ok(Penhas::Minion::Tasks::SendSMS::send_sms($job, test_get_minion_args_job($ENV{LAST_SEND_SMS_JOB_ID})), 'send sms');
    do {
        my $text = trace_popall;
        like $text, qr/minion:send_sms,\+14842918467,SentSmsLog,/, 'logs looks ok';
        my ($log_id) = $text =~ /SentSmsLog,(\d+),?/;

        ok(my $logrow = $schema2->resultset('SentSmsLog')->find($log_id), 'log row found');
        is $logrow->phonenumber, '+14842918467', 'log number ok';
        $logrow->delete;
    };

    my $numero_brazil = '11 912341234';
    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'portugues',
            celular => "021 $numero_brazil",
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 91234-1234')
      ->json_is('/data/nome',        'portugues')->json_is('/data/is_pending', '1')->json_is('/data/is_expired', '0')
      ->json_is('/data/is_accepted', '0')->json_like('/message', qr/Enviamos um SMS/);

    ok(my $id = $t->tx->res->json->{data}{id}, 'has id');

    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'portugues',
            celular => "+55$numero_brazil",
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 91234-1234')
      ->json_like('/message', qr/convite aguardando/);
    my $row_to_be_removed;
    do {
        ok(my $id2 = $t->tx->res->json->{data}{id}, 'has id');
        is $id, $id2, 'same invite';

        $t->put_ok(
            join('', '/me/guardioes/', $id2, '?nome'),
            {'x-api-key' => $session},
        )->status_is(400, 'edit name missing name');

        $t->put_ok(
            join('', '/me/guardioes/', $id2),
            {'x-api-key' => $session},
            form => {nome => 'imasuguni'}
        )->status_is(200, 'edit name');

        ok($row_to_be_removed = $schema2->resultset('ClientesGuardio')->find($id2), 'row found');
        is $row_to_be_removed->nome, 'imasuguni', 'name updated';

        $t->delete_ok(
            join('', '/me/guardioes/', $id),
            {'x-api-key' => $session}
        )->status_is(204);

        $t->put_ok(
            join('', '/me/guardioes/', $id),
            {'x-api-key' => $session},
            form => {nome => 'cannot update'}
        )->status_is(404, 'not found after delete');
        $row_to_be_removed->discard_changes;
        is $row_to_be_removed->status, 'removed_by_user', '$row_to_be_removed is removed';
        ok $row_to_be_removed->deleted_at, 'has deleted_at';

        $t->post_ok(
            '/me/guardioes',
            {'x-api-key' => $session},
            form => {
                nome    => 'novo nao deve enviar sms',
                celular => $numero_brazil,
            }
        )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 91234-1234')
          ->json_like('/message', qr/reativado/);

        $row_to_be_removed->discard_changes;
        is $row_to_be_removed->status,     'pending',                  'pending again';
        is $row_to_be_removed->deleted_at, undef,                      'deleted_at null';
        is $row_to_be_removed->nome,       'novo nao deve enviar sms', 'nome updated';

        # atualiza a data que ele deve vencer:
        $row_to_be_removed->update(
            {
                created_at => \"now() - interval '30 day' ",
                expires_at => \"now() - interval '1 second' ",
                nome       => 'Expiraldo Silva'
            }
        );
    };

    # testa limpeza da cod de operadora
    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'portugues',
            celular => '021 11 943214321',
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 94321-4321')
      ->json_like('/message', qr/Enviamos um SMS/);
    ok(my $id3  = $t->tx->res->json->{data}{id},                      'has id');
    ok(my $row3 = $schema2->resultset('ClientesGuardio')->find($id3), 'row found');
    $row3->update({created_at => \"now() - interval '10 day'"});

    # testa GET
    $t->get_ok(
        join('', '/me/guardioes'),
        {'x-api-key' => $session}
    )->status_is(200)->json_is('/guards/0/rows', [], 'nothing is accepted')
      ->json_is('/guards/0/meta/layout',    'accepted',             'first row layout is accepted')
      ->json_is('/guards/1/meta/layout',    'pending',              'second row layout is pending')
      ->json_is('/guards/1/rows/0/celular', '+1 484-291-8467',      'celular ok')
      ->json_is('/guards/1/rows/1/id',      $id3,                   'id ok do novo convite brazil')
      ->json_is('/guards/2/rows/0/nome',    'Expiraldo Silva',      'id ok')
      ->json_is('/guards/2/rows/0/id',      $row_to_be_removed->id, 'id ok');

    $row_to_be_removed->discard_changes;
    is $row_to_be_removed->status, 'expired_for_not_use', 'status is expired';
    $t->get_ok(
        '/web/guardiao',
        form => {token => $row_to_be_removed->token()}
    )->status_is(200)->json_is('/guardiao/is_expired', '1', 'buscar token expirado deve retornar dados');

    for my $action (qw/accept refuse/) {
        $t->post_ok(
            '/web/guardiao',
            form => {token => $row_to_be_removed->token(), action => $action}
        )->status_is(400)->json_is('/error', 'guard_invite_expired', 'nao deve aceitar com token expirado');
    }
    $t->post_ok(
        '/web/guardiao',
        form => {token => $row_to_be_removed->token(), action => 'foo'}
    )->status_is(400)->json_is('/error', 'action_invalid', 'nao deve aceitar action invalidos');

    # testa cadastrar o numero expirado
    $t->post_ok(
        '/me/guardioes',
        {'x-api-key' => $session},
        form => {
            nome    => 'portugues',
            celular => $row_to_be_removed->celular_formatted_as_national,
        }
    )->status_is(200)->json_is('/data/celular_formatted_as_national', '(11) 91234-1234')
      ->json_like('/message', qr/Enviamos um SMS/);
    ok(my $id4  = $t->tx->res->json->{data}{id},                      'has id');
    ok(my $row4 = $schema2->resultset('ClientesGuardio')->find($id4), 'row found');

    $row_to_be_removed->discard_changes;
    is $row_to_be_removed->status, 'expired_for_not_use', 'status is still expired';
    ok $row_to_be_removed->deleted_at, 'but deleted_at is marked';

    # token expirado (mas apagado por reuso) nao deve funcionar
    $t->get_ok(
        '/web/guardiao',
        form => {token => $row_to_be_removed->token()}
    )->status_is(404)->json_is('/error', 'item_not_found');

    # token com hash invalido
    $t->get_ok(
        '/web/guardiao',
        form => {
            token => substr($row_to_be_removed->token(), 0, -4) . '0AAA',
        }
    )->status_is(400)->json_is('/error', 'token_invalid_hash');

    db_transaction2 {
        is $row4->status, 'pending', 'status do row4 eh pending';
        $row4->update(
            {
                created_at => \"now() - interval '30 day'",
                expires_at => \"now() - interval '1 second'",
                nome       => 'expirando durante aceite'
            }
        );
        $t->post_ok(
            '/web/guardiao',
            form => {
                token  => $row4->token(),
                action => 'accept'
            }
        )->status_is(400)->json_is('/error', 'guard_invite_expired');
    };

    # aceita o token 4
    $row4->discard_changes;
    is $row4->status, 'pending', 'status eh pending';
    $t->get_ok('/web/guardiao' => form => {token => $row4->token()})->status_is(200)
      ->json_is('/guardiao/is_accepted', '0')->json_is('/guardiao/is_pending', '1');
    $t->post_ok(
        '/web/guardiao',
        form => {
            token  => $row4->token(),
            action => 'accept',
        }
    )->status_is(200)->json_is('/guardiao/is_accepted', '1')->json_is('/guardiao/is_pending', '0');
    $row4->discard_changes;
    is $row4->status, 'accepted', 'status eh accepted';
    $t->get_ok('/web/guardiao' => form => {token => $row4->token()})->status_is(200)
      ->json_is('/guardiao/is_accepted', '1')->json_is('/guardiao/is_pending', '0');

    # pode mudar de ideia
    $t->post_ok(
        '/web/guardiao',
        form => {
            token  => $row4->token(),
            action => 'refuse',
        }
    )->status_is(200)->json_is('/guardiao/is_accepted', '0')->json_is('/guardiao/is_pending', '0');
    $row4->discard_changes;
    is $row4->status, 'refused', 'status eh refused';

    $t->get_ok('/web/guardiao' => form => {token => $row4->token()})->status_is(200)
      ->json_is('/guardiao/is_accepted', '0')->json_is('/guardiao/is_pending', '0');

    # aceita o convite 3
    $t->post_ok('/web/guardiao' => form => {token => $row3->token(), action => 'accept'})->status_is(200)
      ->json_is('/guardiao/is_accepted', '1');

# volta a tornar o expiraldo visivel (pois foi removido automaticamente ao reconvidar, mas vamos usa-lo pra testar a listagem)
    $row_to_be_removed->update({deleted_at => undef});

    # testa GET como usuario logado
    $t->get_ok(
        join('', '/me/guardioes'),
        {'x-api-key' => $session}
    )->status_is(200)->json_is('/guards/0/meta/layout', 'accepted', 'first row layout is accepted')
      ->json_is('/guards/0/rows/0/id',       $row3->id,              'row3 is accepted')
      ->json_is('/guards/1/meta/header',     'Pendentes',            'Pendentes')
      ->json_is('/guards/1/meta/layout',     'pending',              'second row layout is pending')
      ->json_is('/guards/1/rows/0/celular',  '+1 484-291-8467',      'celular ok')
      ->json_is('/guards/1/rows/1',          undef,                  'nao tem mais dois convites pendentes')
      ->json_is('/guards/2/meta/header',     'Convites expirados',   'Convites expirados X')
      ->json_is('/guards/2/rows/0/nome',     'Expiraldo Silva',      'id ok')
      ->json_is('/guards/2/meta/can_resend', '1',                    'pode reenviar no expired')
      ->json_is('/guards/2/rows/0/id',       $row_to_be_removed->id, 'id ok')
      ->json_is('/guards/3/meta/can_resend', '0',                    'nao pode reenviar no recusado')
      ->json_is('/guards/3/rows/0/id',       $row4->id,              'id ok')
      ->json_is('/guards/3/meta/header',     'Convites recusados',   'Convites recusados X');

    $t->post_ok(
        join('', '/me/guardioes/alert'),
        {'x-api-key' => $session},
        form => {
            gps_lat  => '12.33445',
            gps_long => '-23.123456789123456',
        }
    )->status_is(200);

    ok(
        my $alert = $schema2->resultset('ClienteAtivacoesPanico')->search(
            {
                cliente_id => $cliente_id,
            }
        )->next(),
        'alert found'
    );
    is $alert->cliente_id, $cliente_id, 'cliente_id match';
    like($alert->alert_sent_to(), qr/5511943214321/, '5511943214321 was logged');
    is $alert->sms_enviados, 1,                     'sms_enviados=1';
    is $alert->gps_lat,      '12.33445',            'lat ok';
    is $alert->gps_long,     '-23.123456789123456', 'long ok';

    $t->post_ok(
        join('', '/me/guardioes/alert'),
        {'x-api-key' => $session},
        form => {
            gps_long => '3.123456789123456',
        }
    )->status_is(400)->json_is('/error', 'too_many_alerts', 'limites de requests por minuto');

    $t->post_ok(
        join('', '/me/guardioes/alert'),
        {'x-api-key' => $session},
        form => {
            gps_lat  => '3.123456789123456',
            gps_long => '3.123456789123456710',
        }
    )->status_is(400)->json_is('/error', 'gps_position_invalid', 'maximo 17 chars')
      ->json_is('/field', 'gps_long', 'erro no campo gps_long');


    my $event_id         = lc 'fb40e9b3-d89e-4a2a-9766-f33e0d430768';
    my $current_date     = DateTime->now->ymd('-');
    my $audio_1_response = $t->post_ok(
        '/me/audios',
        {'x-api-key' => $session},
        form => {
            cliente_created_at => '2047-01-01T00:33:54Z',
            current_time       => '2047-01-01T00:33:56Z',
            event_id           => uc $event_id,
            event_sequence     => '1',
            media              => {file => "$RealBin/../data/gs-16b-1c-44100hz.aac"}
        },
    )->status_is(200)->json_has('/data/id')->tx->res->json;

    ok(my $audio_1 = $schema2->resultset('ClientesAudio')->find($audio_1_response->{data}{id}), 'row found');
    like($audio_1->cliente_created_at, qr/$current_date/, "created at ajusted to $current_date");

    is $audio_1->audio_duration, '15.883', 'duration is right';

    ok(my $event = $schema2->resultset('ClientesAudiosEvento')->find($cliente_id . ':' . $event_id), 'event row found');
    is $audio_1->cliente_id, $cliente_id, 'row is the same client_id';
    is $event->cliente_id,   $cliente_id, 'event row is the same client_id as audio';
    is $event->audio_duration * 1000, 15.883 * 1000, 'duration is ok';
    ok $event->total_bytes > 160000 && $event->total_bytes < 240000, "bytes sum is about right ${\$event->total_bytes}";

    my $audio_2_response = $t->post_ok(
        '/me/audios',
        {'x-api-key' => $session},
        form => {
            cliente_created_at => $now_datetime,
            current_time       => $now_datetime,
            event_id           => $event_id,
            event_sequence     => '2',
            media              => {file => "$RealBin/../data/second-audio-aac.aac"}
        },
    )->status_is(200)->json_has('/data/id')->tx->res->json;

    $event->discard_changes;
    is $event->audio_duration * 1000, (15.883 + 17.369) * 1000, 'duration is ok';
    ok $event->total_bytes > 400000 && $event->total_bytes < 800000, 'bytes sum is about right';

    # duplica o envio do arquivo para verificar que o evento fica ainda OK
    my $audio_2_response_dup = $t->post_ok(
        '/me/audios',
        {'x-api-key' => $session},
        form => {
            cliente_created_at => $now_datetime,
            current_time       => $now_datetime,
            event_id           => $event_id,
            event_sequence     => '2',
            media              => {file => "$RealBin/../data/second-audio-aac.aac"}
        },
    )->status_is(200)->json_has('/data/id')->tx->res->json;

    ok(my $audio_2     = $schema2->resultset('ClientesAudio')->find($audio_2_response->{data}{id}),     'row found');
    ok(my $audio_2_dup = $schema2->resultset('ClientesAudio')->find($audio_2_response_dup->{data}{id}), 'row found');

    is $audio_2->duplicated_upload,     '1', '$audio_2 is marked as duplicated';
    is $audio_2_dup->duplicated_upload, '0', '$audio_2_dup is the last';
    is $audio_2_dup->audio_duration * 1000, '17.369' * 1000, 'duration is right';

    $event->discard_changes;
    is $event->audio_duration * 1000, (15.883 + 17.369) * 1000, 'duration is ok';
    ok $event->total_bytes > 400000 && $event->total_bytes < 800000, 'bytes sum is about right';

    $t->get_ok(
        '/me/audios',
        {'x-api-key' => $session}
    )->status_is(200)->json_is('/rows/0/data/audio_duration', '0m33s', 'time is human 33 seconds long')
      ->json_is('/rows/0/data/event_id', $event_id, 'event_id is right')
      ->json_like('/rows/0/data/last_cliente_created_at', qr/$current_date/, 'last created_at looks ok')
      ->json_like('/rows/0/data/total_bytes',             qr/KiB/,           'bytes in human')
      ->json_is('/rows/0/meta/download_granted',  '1', 'can be downloaded')
      ->json_is('/rows/0/meta/requested_by_user', '0', 'is not requested_by_user')
      ->json_is('/rows/0/meta/request_granted',   '0', 'therefore request_granted is false');

    $t->get_ok(
        '/me/audios/' . $event_id,
        {'x-api-key' => $session}
    )->status_is(200)->json_has('/audios/0/waveform', 'has waveform')->json_has('/audios/0/bytes', 'row 0 has bytes')
      ->json_is('/audios/0/id',             $audio_1->id,     'row 0 is the right id')
      ->json_is('/audios/1/id',             $audio_2_dup->id, 'row 1 is the right id')
      ->json_is('/audios/0/event_sequence', 1,                'row 0 is the right sequence')
      ->json_is('/audios/1/event_sequence', 2,                'row 1 is the right sequence')
      ->json_is('/audios/2',                undef,            'row 2 does not exists')
      ->json_is('/audios/0/audio_duration', '16s',            'row 0 duration')
      ->json_is('/audios/1/audio_duration', '18s',            'row 0 duration')
      ->json_like('/audios/1/bytes', qr/KiB/, 'row 1 bytes ok');

    $audio_1->media_upload->update(
        {s3_path => $ENV{PUBLIC_API_URL} . '/.tests-assets/t-test-data/gs-16b-1c-44100hz.aac'});
    $audio_2_dup->media_upload->update(
        {s3_path => $ENV{PUBLIC_API_URL} . '/.tests-assets/t-test-data/second-audio-aac.aac'});

    trace_popall();
    $t->get_ok(
        '/me/audios/' . $event_id . '/download',
        {'x-api-key' => $session},
        form => {audio_sequences => '2'}
    )->status_is(200);
    $audio_2_dup->discard_changes;
    is $audio_2_dup->played_count, '1', '1 time downloaded';
    is trace_popall(), 'download', 'download is working';

    # repeat for test cache
    $t->get_ok(
        '/me/audios/' . $event_id . '/download',
        {'x-api-key' => $session},
        form => {audio_sequences => '2'}
    )->status_is(200);
    is trace_popall(), 'cached', 'cache is working';

    # repeat for test concat
    $t->get_ok(
        '/me/audios/' . $event_id . '/download',
        {'x-api-key' => $session},
        form => {audio_sequences => '2,1'}
    )->status_is(200);
    is trace_popall(), 'download,ffmpeg-concat', 'ffmpeg concat is working';


    $audio_2_dup->discard_changes;
    is $audio_2_dup->played_count, '3', '3 times downloaded';

    $event->update({status => 'blocked_access'});
    $t->get_ok(
        '/me/audios/' . $event_id . '/download',
        {'x-api-key' => $session},
        form => {audio_sequences => 'all'}
    )->status_is(400)->json_is('/error', 'audio_blocked_access');

    $t->post_ok(
        '/me/audios/' . $event_id . '/request-access',
        {'x-api-key' => $session},
    )->status_is(200)->json_is('/success', '1');

    $event->discard_changes;
    ok $event->requested_by_user_at, 'has requested_by_user_at';
    is $event->requested_by_user, 1, 'requested_by_user = 1';

    $t->get_ok(
        '/me/audios/' . $event_id . '/download',
        {'x-api-key' => $session},
        form => {audio_sequences => 'all'}
    )->status_is(400)->json_is('/error', 'audio_blocked_access', 'still blocked');

    $t->get_ok(
        '/me/audios',
        {'x-api-key' => $session}
    )->status_is(200)->json_is('/rows/0/data/audio_duration', '0m33s', 'time is human 33 seconds long')
      ->json_is('/rows/0/data/event_id',          $event_id, 'event_id is right')
      ->json_is('/rows/0/meta/download_granted',  '0',       'can be downloaded')
      ->json_is('/rows/0/meta/requested_by_user', '1',       'is requested_by_user')
      ->json_is('/rows/0/meta/request_granted',   '0',       'request_granted is false');

    $event->update({status => 'free_access_by_admin'});
    $t->get_ok(
        '/me/audios/' . $event_id . '/download',
        {'x-api-key' => $session},
        form => {audio_sequences => 'all'}
    )->status_is(200);

    $t->get_ok(
        '/me/audios',
        {'x-api-key' => $session}
    )->status_is(200)->json_is('/rows/0/data/audio_duration', '0m33s', 'time is human 33 seconds long')
      ->json_is('/rows/0/data/event_id',          $event_id, 'event_id is right')
      ->json_is('/rows/0/meta/download_granted',  '1',       'can be downloaded')
      ->json_is('/rows/0/meta/requested_by_user', '1',       'is requested_by_user')
      ->json_is('/rows/0/meta/request_granted',   '1',       'and request_granted is true');


    $t->delete_ok(
        '/me/audios/' . $event_id,
        {'x-api-key' => $session}
    )->status_is(204);

    $t->get_ok(
        '/me/audios/' . $event_id,
        {'x-api-key' => $session}
    )->status_is(400)->json_has('/error', 'invalid')->json_has('/message', 'evento não encontrado');

    $t->delete_ok(
        '/me',
        {'x-api-key' => $session},
        form => {app_version => 'foo', senha_atual => 'W^1SAA3456',}
    )->status_is(204);

    my $user_obj = get_schema2->resultset('Cliente')->find($cliente_id);
    $user_obj->update(
        {
            perform_delete_at => '2020-01-01',
        }
    );
    trace_popall;
    $ENV{MAINTENANCE_SECRET} = '1234';
    $t->get_ok(
        '/maintenance/housekeeping',
        form => {secret => $ENV{MAINTENANCE_SECRET}}
    )->status_is(200);
    ok $ENV{LAST_DELETE_JOB_ID}, 'has $ENV{LAST_DELETE_JOB_ID}';
    ok(
        Penhas::Minion::Tasks::DeleteUser::delete_user($job, test_get_minion_args_job($ENV{LAST_DELETE_JOB_ID})),
        'delete user'
    );
    my $text = trace_popall;
    is $text, "minion:delete_user,$cliente_id", 'logs looks ok';


};

done_testing();

exit;
