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

    $self->helper('add_report_profile' => sub { &add_report_profile(@_) });
    $self->helper('add_block_profile'  => sub { &add_block_profile(@_) });
}

sub add_block_profile {
    my ($c, %opts) = @_;

    my $user       = $opts{user_obj}   or confess 'missing user_obj';
    my $cliente_id = $opts{cliente_id} or confess 'missing cliente_id';
    my $cliente    = $c->schema2->resultset('Cliente')->find($cliente_id);
    die {
        message => 'Não foi possível encontrar o usuário.',
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
    return
      if $c->schema2->resultset('TimelineClientesBloqueado')->search(
        {
            cliente_id       => $user->id,
            block_cliente_id => $cliente_id,
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

    my $report = $c->schema2->resultset('ClientesReportClientesReport')->create(
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
