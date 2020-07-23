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

    $self->helper('cliente_new_audio'  => sub { &cliente_new_audio(@_) });
    $self->helper('cliente_list_audio' => sub { &cliente_list_audio(@_) });
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
                event_id       => $opts{event_id},
                event_sequence => $opts{event_sequence},
            }
        )->update({status => 'sequence_duplicated'}) > 0
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
                    status             => 'free_access',
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
                created_at     => \'NOW()',
                updated_at     => \'NOW()',
                audio_duration => \[
                    "coalesce((
                            SELECT SUM(audio_duration)
                            FROM clientes_audios
                            WHERE cliente_id = ?
                            AND event_id = ?
                            AND status != 'sequence_duplicated'
                        ), -1)", $user_obj->id, $opts{event_id}
                ],
            };
            if ($event) {
                delete $data->{created_at};
                $event->update($data);
            }
            else {
                $rs->create($data);
            }
        }
    );

    use DDP;
    p $row;

    my $message = 'Áudio recebido com sucesso!';
    return {
        message => $message,
        data    => &_format_audio_row($c, $user_obj, $row),
    };
}

sub _format_audio_row {
    my ($c, $user_obj, $row) = @_;

    return {
        id                 => $row->id,
        cliente_created_at => $row->cliente_created_at->datetime,
    };
}


1;
