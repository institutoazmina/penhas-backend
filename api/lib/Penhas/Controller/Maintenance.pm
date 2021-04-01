package Penhas::Controller::Maintenance;
use Mojo::Base 'Penhas::Controller';
use Penhas::Logger;
use Penhas::Utils qw/is_test/;
use Scope::OnExit;

sub check_authorization {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        secret => {required => 1, type => 'Str', max_length => 100},
    );

    $c->reply_forbidden() unless $params->{secret} eq ($ENV{MAINTENANCE_SECRET} || die 'missing MAINTENANCE_SECRET');

    return 1;
}

# executa tarefas para manter o banco atualizado, mas não necessáriamente essenciais
# executar de 1 em 1 hora, por exemplo
sub housekeeping {
    my $c = shift;

    $c->schema2->resultset('ClientesAudiosEvento')->tick_audios_eventos_status();
    $c->tick_ponto_apoio_index();

    my $delete_rs = $c->schema2->resultset('Cliente')->search(
        {
            status              => 'deleted_scheduled',
            deletion_started_at => undef,
            perform_delete_at   => {'<=' => \'now()'},
        },
        {
            columns => ['id'],
        }
    );
    my $minion = Penhas::Minion->instance;
    while (my $r = $delete_rs->next) {

        my $job_id = $minion->enqueue(
            'delete_user',
            [
                $r->id,
            ] => {
                attempts => 5,
            }
        );

        slog_info('Adding job delete_user %s, job id %s', $r->id, $job_id);
        $r->update({deletion_started_at => \'now()'});
        $ENV{LAST_DELETE_JOB_ID} = $job_id;
    }

    my $update_cep = $c->schema2->resultset('Cliente')->search(
        {
            cep_estado => undef,
        },
        {
            columns => ['id'],
        }
    );
    while (my $r = $update_cep->next) {

        my $job_id = $minion->enqueue(
            'cliente_update_cep',
            [
                $r->id,
            ] => {
                attempts => 5,
            }
        );

        slog_info('Adding job cliente_update_cep %s, job id %s', $r->id, $job_id);
        $r->update({cep_estado => '<minion>'});
        $ENV{LAST_DELETE_JOB_ID} = $job_id;
    }

    my $dbh = $c->schema2->storage->dbh;
    $dbh->do(
        "UPDATE
    ponto_apoio_categoria2projetos me
INNER JOIN (
    SELECT
        a.id AS rel_id,
        count(b.id) AS qtde_ponto_apoio
    FROM
        ponto_apoio_categoria2projetos a
        JOIN ponto_apoio b ON b.categoria = a.ponto_apoio_categoria_id
    GROUP BY a.id
) AS subq ON subq.rel_id = me.id SET ponto_apoio_projeto_count = qtde_ponto_apoio;"
    );

    return $c->render(json => {});
}

# cria notificacoes do chat (nao leu em X tempo)
sub tick_notifications {
    my $c = shift;

    if (is_test()) {
        &_tick_notifications($c, 0);
    }
    else {

        $c->subprocess(
            sub {
                my $start     = time();
                my $iteration = 0;
                while (time() - $start < 50) {
                    &_tick_notifications($c, $iteration);
                    $iteration++;
                    sleep 10;
                }
                return 1;
            },
            sub {
                # nothing
            }
        );

    }

    $c->render(json => {});
}

# cria notificacoes do chat (nao leu em X tempo)
sub _tick_notifications {
    my $c         = shift;
    my $iteration = shift;

    my $lkey = $ENV{REDIS_NS} . '_tick_notifications';
    my ($locked) = $c->kv->exec_function('lockSet', 3, $lkey, 50 * 1000, time());
    return unless $locked;
    on_scope_exit { $c->kv()->redis->del($lkey) };

    my $rs = $c->schema2->resultset('ChatClientesNotification');

    $rs = $rs->search({'me.cliente_id' => $ENV{MAINTENANCE_USER_ID}})
      if $ENV{MAINTENANCE_USER_ID};

    if ($iteration == 0) {

        # 1x por request (minuto)
        # "esquece" as mais antigas, pra ser notificado de novo caso tenha nova mensagem
        $rs->search({messaged_at => {'<=' => \'DATE_ADD(NOW(), INTERVAL -1 DAY)'}})->delete;
    }

    # a cada 10 segundos (se tudo estiver correto)
    # cria as notificacoes novas
    my $pending = $rs->search(
        {
            messaged_at          => {'<=' => \'DATE_ADD(NOW(), INTERVAL -5 MINUTE)'},
            notification_created => '0',
        },
        {rows => 100}    # no maximo 100 duma vez
    );

    while (my $r = $pending->next) {

        my $job_id = $c->minion->enqueue(
            'new_notification',
            [
                'new_message',
                {cliente_id => $r->cliente_id(), subject_id => $r->pending_message_cliente_id()}
            ] => {
                attempts => 5,
            }
        );
        slog_info(
            'ChatClientesNotification id %s Adding job new_notification new_message, job id %s',
            $r->id,
            $job_id,
        );
        $r->update({notification_created => 1});
        $ENV{LAST_CHAT_JOB_ID} = $job_id;
    }

    return $c->render(json => {});
}

1;
