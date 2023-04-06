package Penhas::Helpers::Cliente;
use common::sense;
use Carp qw/confess /;
use utf8;

use JSON;
use Penhas::Logger;
use Penhas::Utils;
use DateTime::Format::Pg;
use Encode;

sub setup {
    my $self = shift;

    $self->helper('add_report_profile'     => sub { &add_report_profile(@_) });
    $self->helper('add_block_profile'      => sub { &add_block_profile(@_) });
    $self->helper('remove_blocked_profile' => sub { &remove_blocked_profile(@_) });

    $self->helper('cliente_lista_tarefas'      => sub { &cliente_lista_tarefas(@_) });
    $self->helper('cliente_sync_lista_tarefas' => sub { &cliente_sync_lista_tarefas(@_) });
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
                '-and'      => [\['atualizado_em > to_timestamp(?)', $modificado_apos]]
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

    return {
        tarefas           => [map { &render_tarefa($_) } @$alteracoes],
        tarefas_removidas => $tarefas_removidas
    };

}


sub cliente_sync_lista_tarefas {
    my ($c, %opts) = @_;

    my $user = $opts{user_obj} or confess 'missing user_obj';

    my $mf_id          = $opts{id};
    my $checkbox_feito = $opts{checkbox_feito};
    my $titulo         = $opts{titulo};
    my $descricao      = $opts{descricao};

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

    if ($row->mf_tarefa->eh_customizada && ($titulo || $descricao)) {
        $row->mf_tarefa->update(
            {
                titulo    => $titulo    || $row->mf_tarefa,    # mantem o valor antigo se enviar em branco ou vazio
                descricao => $descricao || $row->mf_tarefa
            }
        );
        $row->update({atualizado_em => \'now()'});
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
