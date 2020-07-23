package Penhas::Helpers::ClienteAudio;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Number::Phone::Lib;
use Penhas::Utils qw/random_string_from is_test/;
use Digest::MD5 qw/md5_hex/;
use Scope::OnExit;


sub setup {
    my $self = shift;

    $self->helper('cliente_new_audio'         => sub { &cliente_new_audio(@_) });
    $self->helper('cliente_list_audio'        => sub { &cliente_list_audio(@_) });
    $self->helper('cliente_list_events_audio' => sub { &cliente_list_events_audio(@_) });
}

sub cliente_new_audio {
    my ($c, %opts) = @_;

    my $user_obj           = $opts{user_obj}           or confess 'missing user_obj';
    my $cliente_created_at = $opts{cliente_created_at} or confess 'missing cliente_created_at';
    my $media_upload       = $opts{media_upload}       or confess 'missing media_upload';

    for my $col (qw/audio_duration event_sequence waveform/) {
        $opts{$col} or confess "missing $col";
    }

    $opts{event_id} = lc $opts{event_id};

    my ($locked, $lock_key) = $c->kv->lock_and_wait('audio:event_id' . $opts{event_id});
    on_scope_exit { $c->kv->redis->del($lock_key) };
    $c->reply_invalid_param('event_id', 'already-locked') if !$locked;

    # marca como duplicado caso ja exista o mesmo event_sequence para o mesmo event_id
    if (
        $user_obj->clientes_audios->search(
            {
                event_id          => $opts{event_id},
                event_sequence    => $opts{event_sequence},
                duplicated_upload => 0,
            }
        )->update({duplicated_upload => '1'}) > 0
      )
    {
        slog_info(
            "event_id %s event_sequence %s was already previously sent...",
            $opts{event_id},
            $opts{event_sequence}
        );
    }

    my $row;
    $c->schema2->txn_do(
        sub {
            $row = $user_obj->clientes_audios->create(
                {
                    media_upload_id    => $media_upload->id,
                    cliente_created_at => $cliente_created_at,
                    created_at         => \'NOW()',
                    waveform_base64    => $opts{waveform},
                    event_id           => $opts{event_id},
                    event_sequence     => $opts{event_sequence},
                    audio_duration     => $opts{audio_duration},
                }
            );

            my $rs    = $user_obj->clientes_audios_eventos;
            my $event = $rs->find($opts{event_id});
            my $data  = {
                event_id       => $opts{event_id},
                status         => 'free_access',
                created_at     => \'NOW()',
                updated_at     => \'NOW()',
                audio_duration => \[
                    "coalesce((
                            SELECT SUM(me.audio_duration)
                            FROM clientes_audios me
                            WHERE me.cliente_id = ?
                            AND me.event_id = ?
                            AND me.duplicated_upload = '0'
                        ), -1)", $user_obj->id, $opts{event_id}
                ],
                total_bytes => \[
                    "coalesce((
                            SELECT SUM(up.file_size)
                            FROM clientes_audios me
                            JOIN media_upload up ON up.id = me.media_upload_id
                            WHERE me.cliente_id = ?
                            AND me.event_id = ?
                            AND me.duplicated_upload = '0'
                        ), 0)", $user_obj->id, $opts{event_id}
                ],
            };
            if ($event) {
                delete $data->{created_at};
                delete $data->{status};
                $event->update($data);
            }
            else {
                $rs->create($data);
            }
        }
    );

    my $message = 'Áudio recebido com sucesso!';
    return {
        message => $message,
        success => 1,
        data    => {id => $row->id}
    };
}

sub _format_audio_row {
    my ($c, $user_obj, $row) = @_;

    return {
        id                 => $row->id,
        cliente_created_at => $row->cliente_created_at->datetime,
    };
}

sub cliente_list_events_audio {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

=pod
    $user_obj->clientes_guardioes_rs->expires_pending_invites();
    my $invites_max     = $user_obj->clientes_guardioes_rs->max_invites_count();
    my $remaing_invites = $invites_max - $user_obj->clientes_guardioes_rs->used_invites_count();

    my $filtered_rs = $user_obj->clientes_guardioes_rs->search_rs(
        {
            '-or' => [
                {'me.status'     => {in   => [qw/pending accepted expired_for_not_use/]}},
                {'me.refused_at' => {'!=' => undef}}
            ]
        },
        {order_by => [qw/me.status/, {'-desc' => 'me.created_at'}]}
    );

    my $by_status = {};
    while (my $r = $filtered_rs->next) {
        push $by_status->{$r->status()}->@*, $r;
    }

    my $config_map = {
        free_access => {
            header         => 'Guardiões',
            description    => 'Guardiões que recebem seus pedidos de socorro.',
            delete_warning => '',
            can_resend     => 0,
            layout         => 'accepted',
        },
        pending => {
            header         => 'Pendentes',
            description    => 'Guardiões que ainda não aceitaram seu convite.',
            delete_warning => '',
            can_resend     => 0,
            layout         => 'pending',
        },
        expired_for_not_use => {
            header         => 'Convites expirados',
            description    => 'Convites não podem mais serem aceitos aceitos, convite novamente',
            delete_warning => '',
            can_resend     => 1,
            layout         => 'pending',
        },
        refused => {
            header => 'Convites recusados',
            description =>
              'Convite recusado! O guardião ainda pode aceitar o convite usando o mesmo link. Use o botão 🗑️ para cancelar o convite.',
            delete_warning =>
              'Após apagar um convite recusado, você não poderá convidar este número por até 7 dias.',
            can_resend => 0,
            layout     => 'pending',
        },
    };
    my @guards;

    for my $type (qw/accepted pending expired_for_not_use refused/) {

        my $config = $config_map->{$type};

        my @rows = $by_status->{$type}->@*;

        next if @rows == 0 && $type =~ /^(expired_for_not_use|refused)$/;

        push @guards, {
            meta => $config,
            rows => [
                map {
                    +{
                        id       => $_->id(),
                        nome     => $_->nome(),
                        celular  => $_->celular_formatted_as_national(),
                        subtexto => $_->subtexto(),
                    }
                } @rows
            ],
        };


    }

    return {
        remaing_invites => $remaing_invites,
        invites_max     => $invites_max,
        guards          => \@guards

    };
=cut

}


1;
