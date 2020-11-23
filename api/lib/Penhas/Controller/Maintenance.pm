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

    return $c->render(json => {});
}

# cria notificacoes do chat (nao leu em X tempo)
sub tick_notifications {
    my $c = shift;

    if (is_test()) {
        &_tick_notifications($c);
    }
    else {

        $c->subprocess(
            sub {
                my $start = time();
                while (time() - $start < 50) {
                    &_tick_notifications($c);
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
    my $c = shift;

    my $lkey = $ENV{REDIS_NS} . '_tick_notifications';
    my ($locked) = $c->kv->exec_function('lockSet', 3, $lkey, 50 * 1000, time());
    return unless $locked;
    on_scope_exit { $c->kv()->redis->del($lkey) };

    my $rs = $c->schema2->resultset('ChatClientesNotification');

    $rs = $rs->search({'me.cliente_id' => $ENV{MAINTENANCE_USER_ID}})
      if $ENV{MAINTENANCE_USER_ID};

    # "esquece" as mais antigas, pra ser notificado de novo caso tenha nova mensagem
    $rs->search({messaged_at => {'<=' => \'DATE_ADD(NOW(), INTERVAL -1 DAY)'}})->delete;

    # cria as notificacoes novas
    my $pending = $rs->search(
        {
            messaged_at          => {'<=' => \'DATE_ADD(NOW(), INTERVAL -5 MINUTE)'},
            notification_created => '0',
        },
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
