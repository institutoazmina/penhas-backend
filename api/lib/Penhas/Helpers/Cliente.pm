package Penhas::Helpers::Cliente;
use common::sense;
use Carp qw/confess /;
use utf8;

use JSON qw/from_json to_json/;
use Penhas::Logger;
use Penhas::Utils;
use DateTime::Format::Pg;
use Encode;

our $NEW_TASK_TOKEN = $ENV{NEW_TASK_TOKEN} || '';

my $descricao
  = 'O Manual de Fuga vai ajudá-la a criar um plano de saída do ambiente doméstico. Por isso, dedique um tempo, e responda ao máximo de perguntas, para podermos personalizar uma lista de ações essenciais para o seu planejamento. Ele será mostrada somente depois que você concluir a interação.';

sub setup {
    my $self = shift;

    $self->helper('add_report_profile'     => sub { &add_report_profile(@_) });
    $self->helper('add_block_profile'      => sub { &add_block_profile(@_) });
    $self->helper('remove_blocked_profile' => sub { &remove_blocked_profile(@_) });

    $self->helper('cliente_lista_tarefas'      => sub { &cliente_lista_tarefas(@_) });
    $self->helper('cliente_sync_lista_tarefas' => sub { &cliente_sync_lista_tarefas(@_) });
    $self->helper('cliente_nova_tarefas'       => sub { &cliente_nova_tarefas(@_) });
    $self->helper('cliente_mf_assistant'       => sub { &cliente_mf_assistant(@_) });

    $self->helper('cliente_mf_add_tarefa_por_codigo' => sub { &cliente_mf_add_tarefa_por_codigo(@_) });
    $self->helper('cliente_mf_add_tag_by_code'       => sub { &cliente_mf_add_tag_by_code(@_) });
    $self->helper('cliente_mf_clear_tasks'           => sub { &cliente_mf_clear_tasks(@_) });

}

sub cliente_mf_assistant {
    my ($c, %opts) = @_;

    my $user = $opts{user_obj} or confess 'missing user_obj';
    return {} unless $user->is_female();

    slog_info('calling ensure_cliente_mf_session_control_exists');
    my $mf_sc = $user->ensure_cliente_mf_session_control_exists();

    my $config = {
        'onboarding' => {t => 'Criar o meu Manual de Fuga',         d => $descricao},
        'inProgress' => {t => 'Continuar preenchendo o meu Manual', d => $descricao},
        'completed'  => {t => 'Refazer o meu Manual de Fuga',       d => $descricao},
    };
    my $title    = $config->{$mf_sc->status()}{t};
    my $subtitle = $config->{$mf_sc->status()}{d};

    # no onboarding e completed o body é vazio, precisa de um POST /me/quiz (só precisa passar o session_id)
    # para iniciar a session com o primeiro valor da mf_questionnaire_order (geralmente o B0)
    my $quiz_session = {
        current_msgs => [],
        prev_msgs    => undef
    };

    slog_info('calling current_clientes_quiz_session');
    my $mf_current_session_id = $mf_sc->get_column('current_clientes_quiz_session');
    if ($mf_current_session_id) {
        slog_info('calling user_get_quiz_session with session_id=%s', $mf_current_session_id);

        $quiz_session = $c->user_get_quiz_session(
            user       => {$user->get_columns()},
            session_id => $mf_current_session_id
        );

        if (!$quiz_session) {
            slog_info(
                'failed to load current_clientes_quiz_session user=%s $mf_current_session_id=%s',
                $user->id, $mf_current_session_id,
            );
            $user->remove_cliente_mf_session_control();
        }
        else {
            slog_info('calling load_quiz_session');

            $c->load_quiz_session(session => $quiz_session, user => {$user->get_columns()}, user_obj => $user);

            $quiz_session = $c->stash('quiz_session');
        }
    }

    my $ret = {
        title    => $title,
        subtitle => $subtitle,

        quiz_session => {
            session_id => $user->mf_assistant_session_id(),
            %$quiz_session,
        }
    };


    return {mf_assistant => $ret};
}

sub cliente_mf_clear_tasks {
    my ($c, %opts) = @_;

    my $user = $opts{user_obj} or confess 'missing user_obj';

    $c->schema2->resultset('MfClienteTarefa')->search(
        {
            removido_em => undef,
            cliente_id  => $user->id,
        }
    )->update({removido_em => \'now()'});


}


sub cliente_mf_add_tag_by_code {
    my ($c, %opts) = @_;

    my $user    = $opts{user_obj} or confess 'missing user_obj';
    my $codigos = $opts{codigos}  or confess 'missing codigos';

    $c->schema2->txn_do(
        sub {
            my @tarefas = $c->schema2->resultset('MfTag')->search(
                {
                    code => {in => $codigos},
                },
                {
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                    columns      => ['id', 'code'],
                }
            )->all;

            my @already_exists = $c->schema2->resultset('ClienteTag')->search(
                {
                    cliente_id => $user->id,

                    mf_tag_id => {'in' => [map { $_->{id} } @tarefas]}
                },
                {
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                    columns      => ['mf_tag_id']
                }
            )->all();

            my $exists_by_id = {};
            $exists_by_id->{$_->{mf_tag_id}} = 1 for @already_exists;

            for my $tarefa (@tarefas) {
                next if $exists_by_id->{$tarefa->{id}};

                slog_info(
                    'adding mf_cliente_tag user=%s $mf_tag_id=%s %s',
                    $user->id, $tarefa->{id}, $tarefa->{code},
                );

                $c->schema2->resultset('ClienteTag')->create(
                    {
                        cliente_id    => $user->id,
                        atualizado_em => \'now()',
                        mf_tag_id     => $tarefa->{id},
                    }
                );
            }
        }
    );
}

sub cliente_mf_add_tarefa_por_codigo {
    my ($c, %opts) = @_;

    my $user    = $opts{user_obj} or confess 'missing user_obj';
    my $codigos = $opts{codigos}  or confess 'missing codigos';

    $c->schema2->txn_do(
        sub {
            my @tarefas = $c->schema2->resultset('MfTarefa')->search(
                {
                    codigo => {in => $codigos},
                },
                {
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                    columns      => ['id', 'codigo'],
                }
            )->all;

            my @already_exists = $c->schema2->resultset('MfClienteTarefa')->search(
                {
                    removido_em => undef,
                    cliente_id  => $user->id,

                    mf_tarefa_id => {'in' => [map { $_->{id} } @tarefas]}
                },
                {
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                    columns      => ['mf_tarefa_id']
                }
            )->all();

            my $exists_by_id = {};
            $exists_by_id->{$_->{mf_tarefa_id}} = 1 for @already_exists;

            for my $tarefa (@tarefas) {
                next if $exists_by_id->{$tarefa->{id}};

                slog_info(
                    'adding mf_cliente_tarefa user=%s $tarefa_id=%s %s',
                    $user->id, $tarefa->{id}, $tarefa->{codigo},
                );

                $c->schema2->resultset('MfClienteTarefa')->create(
                    {
                        removido_em   => undef,
                        cliente_id    => $user->id,
                        atualizado_em => \'now()',
                        mf_tarefa_id  => $tarefa->{id},
                    }
                );
            }
        }
    );


}

# será usado apenas para o desenvolvimento, não será usado em produção
# o token de prod não será setado, então ficara desabilitado
sub cliente_nova_tarefas {
    my ($c, %opts) = @_;

    my $user      = $opts{user_obj} or confess 'missing user_obj';
    my $titulo    = $opts{titulo};
    my $descricao = $opts{descricao};
    my $agrupador = $opts{agrupador};
    my $token     = $opts{token};

    die {
        message => 'Token não confere',
        error   => 'mftoken_invalid'
      }
      unless $NEW_TASK_TOKEN
      && $token eq $NEW_TASK_TOKEN;


    my $tipo           = 'checkbox';
    my $eh_customizada = 'false';

    if ($opts{checkbox_contato}) {
        $tipo           = 'checkbox_contato';
        $eh_customizada = 'true';
    }

    my $id;

    $c->schema2->txn_do(
        sub {
            my $tarefa_id = $c->schema2->resultset('MfTarefa')->create(
                {

                    titulo         => $titulo,
                    descricao      => $descricao,
                    agrupador      => $agrupador,
                    tipo           => $tipo,
                    codigo         => '',
                    eh_customizada => $eh_customizada,
                }
            );

            $id = $c->schema2->resultset('MfClienteTarefa')->create(
                {
                    removido_em   => undef,
                    cliente_id    => $user->id,
                    atualizado_em => \'now()',
                    mf_tarefa_id  => $tarefa_id->id(),
                }
            )->id();
        }
    );

    return {message => 'entrada criada com sucesso!', id => $id};
}

sub cliente_lista_tarefas {
    my ($c, %opts) = @_;

    my $user            = $opts{user_obj} or confess 'missing user_obj';
    my $modificado_apos = $opts{modificado_apos};

    my $alteracoes = [
        $c->schema2->resultset('MfClienteTarefa')->search(
            {
                removido_em => undef,
                cliente_id  => $user->id,
                '-and'      => [\['atualizado_em >= to_timestamp(?)', $modificado_apos]]
            },
            {prefetch => 'mf_tarefa'}
        )->all
    ];

    my $tarefas_removidas = [
        map { $_->{id} } $c->schema2->resultset('MfClienteTarefa')->search(
            {
                removido_em => {'!=' => undef},
                cliente_id  => $user->id,
                '-and'      => [\['removido_em >= to_timestamp(?)', $modificado_apos]]
            },
            {
                select       => ['id'],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        )->all
    ];

    my @botoes = ();

    # se já iniciou alguma vez
    my $has_mf_sc = $c->schema2->resultset('ClienteMfSessionControl')->search(
        {
            cliente_id => $user->id,
            status     => {'not in' => ['onboarding']}
        }
    )->count();
    if ($has_mf_sc) {
        push @botoes, &render_botao_endereco($user);
    }

    return {
        tarefas => [
            (map { &render_tarefa($_) } @$alteracoes),
            @botoes
        ],
        tarefas_removidas => $tarefas_removidas
    };

}


sub cliente_sync_lista_tarefas {
    my ($c, %opts) = @_;

    my $user = $opts{user_obj} or confess 'missing user_obj';

    my $mf_id          = $opts{id};
    my $checkbox_feito = $opts{checkbox_feito};

    my $row = $c->schema2->resultset('MfClienteTarefa')->search(
        {
            'me.removido_em' => undef,
            'me.cliente_id'  => $user->id,
            'me.id'          => $mf_id
        },
        {prefetch => 'mf_tarefa'}
    )->next;
    die {
        message => 'Não foi possível encontrar a tarefa.',
        error   => 'mfclientetarefa_id_not_found'
    } unless $row;

    if ($opts{remove}) {
        $row->update({removido_em => \'now()'});

        return {message => 'Removido com sucesso.'};
    }

    my $campo_livre = ($opts{campo_livre} ? $opts{campo_livre} : undef);
    $campo_livre = to_json($campo_livre) if (defined $campo_livre && ref $campo_livre);

    $c->schema2->txn_do(
        sub {
            if ($row->mf_tarefa->eh_customizada) {
                $row->mf_tarefa->update(
                    {
                        campo_livre => $campo_livre,
                    }
                );
                $row->update({atualizado_em => \'now()'});
            }
            elsif (!$row->mf_tarefa->eh_customizada && $campo_livre) {
                $c->app->log->debug(
                    'cliente_sync_lista_tarefas chamado com campo livre mas tarefa não é eh_customizada. Valor ignorado'
                      . to_json($campo_livre));
            }

            # se mudou o valor do checkbox
            if (!!$row->checkbox_feito() ne !!$checkbox_feito) {
                $row->update(
                    {
                        checkbox_feito => $checkbox_feito ? 'true' : 'false',
                        atualizado_em  => \'now()',

                        $checkbox_feito
                        ? (
                            # guarda a primeira vez que marcou como feito
                            $row->checkbox_feito_checked_first_updated_at() ? () : (
                                checkbox_feito_checked_first_updated_at => \'now()',
                            ),

                            # e a ultima vez que marcou como feito
                            checkbox_feito_checked_last_updated_at => \'now()'
                          )
                        : (
                            # guarda a primeria vez que como não-feito
                            $row->checkbox_feito_unchecked_first_updated_at() ? () : (
                                checkbox_feito_unchecked_first_updated_at => \'now()',
                            ),

                            # e a ultima vez que marcou como não-feito
                            checkbox_feito_unchecked_last_updated_at => \'now()'
                        )
                    }
                );
            }
        }
    );

    return {message => 'Atualizado com sucesso.'};
}


sub render_tarefa {
    my ($mf_cliente_tarefa) = @_;

    my $mf_tarefa = $mf_cliente_tarefa->mf_tarefa;
    return {
        id             => $mf_cliente_tarefa->id(),
        checkbox_feito => $mf_cliente_tarefa->checkbox_feito(),
        atualizado_em  => $mf_cliente_tarefa->atualizado_em->epoch(),
        tipo           => $mf_tarefa->tipo(),
        eh_customizada => $mf_tarefa->eh_customizada(),
        titulo         => $mf_tarefa->titulo(),
        descricao      => $mf_tarefa->descricao(),
        agrupador      => $mf_tarefa->agrupador(),
        campo_livre    => ($mf_tarefa->campo_livre() ? from_json($mf_tarefa->campo_livre()) : undef),
    };
}

sub render_botao_endereco {
    my ($user) = @_;

    return {
        id            => -1,
        atualizado_em => time(),
        tipo          => 'button',
        descricao     => '',
        agrupador     => 'Transporte',
        data          => {
            label => 'Revistar Transporte',
            route => '/quiz/start?session_id=' . $user->mf_redo_addr_session_id(),
        }
    };
}

sub add_block_profile {
    my ($c, %opts) = @_;

    my $user       = $opts{user_obj}   or confess 'missing user_obj';
    my $cliente_id = $opts{cliente_id} or confess 'missing cliente_id';
    my $cliente    = $c->schema2->resultset('Cliente')->find($cliente_id);
    die {
        message => 'Não foi possível encontrar a usuária.',
        error   => 'cliente_id_not_found'
    } unless $cliente;

    die {
        message => 'Não é possível bloquear o seu próprio perfil.',
        error   => 'cliente_id_invalid'
    } if ($user->id == $cliente_id);

    slog_info(
        'add_block_profile user=%s $cliente_id=%s',
        $user->id, $cliente_id,
    );


    # só pode dar o block 1x
    # se defendendo contra um flood pra aumentar a timeline_clientes_bloqueados_ids
    return
      if $c->schema2->resultset('TimelineClientesBloqueado')->search(
        {
            cliente_id       => $user->id,
            block_cliente_id => $cliente_id,
            valid_until      => 'infinity'
        }
    )->count() > 0;

    $c->schema2->txn_do(
        sub {
            my $block = $c->schema2->resultset('TimelineClientesBloqueado')->create(
                {
                    cliente_id       => $user->id,
                    block_cliente_id => $cliente_id,
                    created_at       => \'NOW()',
                }
            );
            die 'id missing' unless $block->id;

            $user->update(
                {
                    timeline_clientes_bloqueados_ids =>
                      \["array_append(timeline_clientes_bloqueados_ids, ?)", $cliente_id]
                }
            );
        }
    );

}

sub remove_blocked_profile {
    my ($c, %opts) = @_;

    my $user       = $opts{user_obj}   or confess 'missing user_obj';
    my $cliente_id = $opts{cliente_id} or confess 'missing cliente_id';
    my $cliente    = $c->schema2->resultset('Cliente')->find($cliente_id);
    die {
        message => 'Não foi possível encontrar a usuária.',
        error   => 'cliente_id_not_found'
    } unless $cliente;

    slog_info(
        'remove_blocked_profile user=%s $cliente_id=%s',
        $user->id, $cliente_id,
    );

    $c->schema2->txn_do(
        sub {
            my $current_blocked = $c->schema2->resultset('TimelineClientesBloqueado')->search(
                {
                    cliente_id       => $user->id,
                    block_cliente_id => $cliente_id,
                    valid_until      => 'infinity'
                }
            );

            if ($current_blocked) {
                $current_blocked->update({valid_until => \'NOW()'});
            }

            $user->update(
                {
                    timeline_clientes_bloqueados_ids =>
                      \["array_remove(timeline_clientes_bloqueados_ids, ?)", $cliente_id]
                }
            );
        }
    );

}

sub add_report_profile {
    my ($c, %opts) = @_;

    my $user       = $opts{user_obj}   or confess 'missing user_obj';
    my $reason     = $opts{reason}     or confess 'missing reason';
    my $cliente_id = $opts{cliente_id} or confess 'missing cliente_id';
    my $cliente    = $c->schema2->resultset('Cliente')->find($cliente_id);
    die {
        message => 'Não foi possível encontrar o usuário.',
        error   => 'cliente_id_not_found'
    } unless $cliente;

    slog_info(
        'add_report_profile user=%s $cliente_id=%s, reason=%s',
        $user->id, $cliente_id, $reason,
    );

    my $report = $c->schema2->resultset('ClientesReport')->create(
        {
            reason              => $reason,
            cliente_id          => $user->id,
            reported_cliente_id => $cliente_id,
            created_at          => \'NOW()',
        }
    );
    die 'id missing' unless $report->id;


    if ($ENV{EMAIL_TWEET_REPORTADO}) {

        $c->schema->resultset('EmaildbQueue')->create(
            {
                config_id => 1,
                template  => 'cliente_reportado.html',
                to        => $ENV{EMAIL_TWEET_REPORTADO},
                subject   => 'PenhaS - Usuária reportada',
                variables => to_json(
                    {
                        cliente => {
                            id            => $cliente->id,
                            nome_completo => $cliente->nome_completo,
                        },
                        report => {
                            id     => $report->id,
                            reason => $reason,
                        }
                    }
                ),
            }
        );
    }

    return {id => $report->id};
}

1;
