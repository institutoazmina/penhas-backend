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

    if (!is_test()) {
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
            $r->update({cep_estado => ''});
        }
    }

    my $dbh = $c->schema2->storage->dbh;

    $dbh->do(
        "UPDATE tweets x SET qtde_comentarios = (
            SELECT
                count(1)
            FROM
                tweets me
            WHERE
                me.status = 'published'
                AND x.id = me.parent_id
            )
        WHERE qtde_comentarios != (
            SELECT
                count(1)
            FROM
                tweets me
            WHERE
                me.status = 'published'
                AND x.id = me.parent_id
        );
"
    );

    $dbh->do(
        "UPDATE tweets me SET qtde_likes = (
            SELECT
                count(1)
            FROM
                tweets_likes x
            WHERE x.tweet_id = me.id
            )
        WHERE qtde_likes != (
            SELECT
                count(1)
            FROM
                tweets_likes x
            WHERE x.tweet_id = me.id
        );
"
    );

    $dbh->do(
        "UPDATE cliente_mf_session_control SET
        status = 'onboarding',
        current_clientes_quiz_session = null,
        completed_questionnaires_id = '{}'
        WHERE now() - started_at > '30 days'::interval
        AND status='inProgress';
"
    );


    my $err = '';
    $err .= 'failed redis' unless Penhas::KeyValueStorage->instance->redis->ping() eq 'PONG';

    my $errCount = $c->schema->resultset('EmaildbQueue')->search(
        {
            -'or' => [
                {sent   => 0},
                {errmsg => {'!=' => undef}}
            ]
        }
    )->count();
    $err .= 'failed EmaildbQueue' if $errCount > 0;

    return $c->render(
        json => {
            is_ok  => $err eq '' ? 'OK' : 'ERR',
            errors => $err,
        }
    );
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
        $rs->search({messaged_at => {'<=' => \"NOW() + INTERVAL '-1 DAY'"}})->delete;
    }

    # a cada 10 segundos (se tudo estiver correto)
    # cria as notificacoes novas
    my $pending = $rs->search(
        {
            messaged_at          => {'<=' => \"NOW() + INTERVAL '-5 MINUTE'"},
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

    return 1;
}

sub fix_tweets_parent_id {

    my $c = shift;

    my $rs = $c->schema2->resultset('Tweet')->search(
        {
            parent_id => {'!=' => undef},
        },
        {
            columns => ['id', 'parent_id'],
        }
    );
    while (my $r = $rs->next) {

        my $reply_to = $r->parent_id;

        # procura o tweet raiz
        while (1) {
            my $parent
              = $c->schema2->resultset('Tweet')->search({id => $reply_to}, {columns => ['id', 'parent_id']})->next;
            last                           if !$parent;
            $reply_to = $parent->parent_id if $parent->parent_id;
            last                           if !$parent->parent_id;
            last                           if $parent->parent_id eq $parent->id;    # just in case
        }
        $r->update({parent_id => $reply_to});
    }

    $rs = $c->schema2->resultset('Tweet')->search(
        {},
        {
            columns => ['id', 'parent_id'],
        }
    );

    while (my $r = $rs->next) {

        $rs->search({id => $r->id})->update(
            {
                qtde_comentarios     => \['(select count(1) from tweets where parent_id = ?)', $r->id],
                ultimo_comentario_id => \[
                    '(select max(id) from tweets where parent_id = ?)',
                    $r->id
                ],
            }
        );
    }


    return $c->render(json => {});
}

1;
