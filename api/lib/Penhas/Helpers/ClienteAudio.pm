package Penhas::Helpers::ClienteAudio;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Number::Phone::Lib;
use Penhas::Utils qw/random_string_from is_test time_seconds_fmt is_uuid_v4 is_test/;
use Digest::MD5 qw/md5_hex/;
use Scope::OnExit;
use Mojo::Util qw/humanize_bytes/;
use POSIX qw/ceil/;

sub setup {
    my $self = shift;

    $self->helper('cliente_new_audio'            => sub { &cliente_new_audio(@_) });
    $self->helper('cliente_list_audio'           => sub { &cliente_list_audio(@_) });
    $self->helper('cliente_list_events_audio'    => sub { &cliente_list_events_audio(@_) });
    $self->helper('cliente_detail_events_audio'  => sub { &cliente_detail_events_audio(@_) });
    $self->helper('cliente_delete_events_audio'  => sub { &cliente_delete_events_audio(@_) });
    $self->helper('cliente_audio_play_inc'       => sub { &cliente_audio_play_inc(@_) });
    $self->helper('cliente_request_audio_access' => sub { &cliente_request_audio_access(@_) });


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
    $c->reply_invalid_param('event_id', 'invalid') unless is_uuid_v4($opts{event_id});

    my ($locked, $lock_key) = $c->kv->lock_and_wait('audio:event_id' . $opts{event_id});
    on_scope_exit { $c->kv->redis->del($lock_key) };
    $c->reply_invalid_param('event_id', 'already-locked') if !$locked;

    my $real_event_id = $user_obj->id_composed_fk($opts{event_id});

    # marca como duplicado caso ja exista o mesmo event_sequence para o mesmo event_id
    if (
        $user_obj->clientes_audios->search(
            {
                event_id          => $real_event_id,
                event_sequence    => $opts{event_sequence},
                duplicated_upload => 0,
            }
        )->update({duplicated_upload => '1'}) > 0
      )
    {
        slog_info(
            "event_id %s event_sequence %s was already previously sent...",
            $real_event_id,
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
                    event_id           => $real_event_id,
                    event_sequence     => $opts{event_sequence},
                    audio_duration     => $opts{audio_duration},
                }
            );

            my $rs    = $user_obj->clientes_audios_eventos;
            my $event = $rs->find($real_event_id);
            my $data  = {
                event_id                => $real_event_id,
                status                  => 'free_access',
                created_at              => \'NOW()',
                updated_at              => \'NOW()',
                last_cliente_created_at => $cliente_created_at,
                audio_duration          => \[
                    "coalesce((
                            SELECT SUM(me.audio_duration)
                            FROM clientes_audios me
                            WHERE me.cliente_id = ?
                            AND me.event_id = ?
                            AND me.duplicated_upload = '0'
                        ), -1)", $user_obj->id, $real_event_id
                ],
                total_bytes => \[
                    "coalesce((
                            SELECT SUM(up.file_size)
                            FROM clientes_audios me
                            JOIN media_upload up ON up.id = me.media_upload_id
                            WHERE me.cliente_id = ?
                            AND me.event_id = ?
                            AND me.duplicated_upload = '0'
                        ), 0)", $user_obj->id, $real_event_id
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

sub cliente_list_events_audio {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $event_id = $opts{event_id};

    $user_obj->clientes_audios_eventos->tick_audios_eventos_status();

    my $filtered_rs = $user_obj->clientes_audios_eventos->search_rs(
        {
            'me.status'     => {in => [qw/free_access blocked_access free_access_by_admin/]},
            'me.deleted_at' => undef,
            (defined $event_id ? ('me.event_id' => $user_obj->id_composed_fk($event_id)) : ()),
        },
        {
            order_by => [{'-desc' => 'me.last_cliente_created_at'}, {'-desc' => 'me.created_at'}],
            rows     => 500                                                                          # just int case
        }
    );

    my @rows;
    while (my $r = $filtered_rs->next) {

        return $r if defined $event_id;
        push @rows, {
            data => {
                event_id                => $r->fake_event_id(),
                audio_duration          => time_seconds_fmt($r->audio_duration()),
                audio_duration_secs     => $r->audio_duration(),
                last_cliente_created_at => $r->last_cliente_created_at->datetime(),
                total_bytes             => humanize_bytes($r->total_bytes()),
            },

            meta => {
                requested_by_user => $r->requested_by_user                ? 1 : 0,
                request_granted   => $r->status eq 'free_access_by_admin' ? 1 : 0,
                download_granted  => $r->is_download_granted()            ? 1 : 0,
            },

        };
    }
    return undef if defined $event_id;

    my $total_count = $user_obj->clientes_audios_eventos->count(
        {
            # imaginei inicialmente seria apenas o count apenas dos audios escondidos.
            # nesse caso, seria só descomentar o filtro abaixo:
            # 'me.event_id'   => {'not in' => [map { $_->{event_id} } @rows]},
            'me.deleted_at' => undef,
            (defined $event_id ? ('me.event_id' => $user_obj->id_composed_fk($event_id)) : ()),
        }
    );

    my $message = '';
    if ($total_count > 0) {
        $message = ($total_count == 1 ? "Você tem 1 áudio gravado." : "Você tem $total_count áudios gravados.")
          . 'Gravações com mais de 30 dias não ficam mais visíveis para você, mas permanecem armazenadas em nossos servidores por até cinco anos. Caso queira os arquivos, solicite através do e-mail penhas@azmina.com.br.';
    }

    return {
        rows    => \@rows,
        message => $message
    };
}

sub cliente_delete_events_audio {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $event_id = $opts{event_id} or confess 'missing event_id';

    $c->reply_invalid_param('event_id', 'invalid') unless is_uuid_v4($event_id);

    my $event = $c->cliente_list_events_audio(%opts);
    $c->reply_invalid_param('event_id', 'evento não encontrado') unless $event;

    $event->update(
        {
            deleted_at => \'NOW()',
        }
    );

    return 1;
}

sub cliente_request_audio_access {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $event_id = $opts{event_id} or confess 'missing event_id';

    $c->reply_invalid_param('event_id', 'invalid') unless is_uuid_v4($event_id);

    my $event = $c->cliente_list_events_audio(%opts);
    $c->reply_invalid_param('event_id', 'evento não encontrado') unless $event;

    $event->update(
        {
            requested_by_user    => 1,
            requested_by_user_at => \'NOW()',
        }
    );

    my $message
      = 'A administração do PenhaS vai avaliar seu pedido. Retorne a esta seção em 48h. Caso não haja mudança no status, envie um e-mail para contato@penhas.com.br';
    return {
        message => $message,
        success => 1,
    };
}


sub cliente_detail_events_audio {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $event_id = $opts{event_id} or confess 'missing event_id';

    $c->reply_invalid_param('event_id', 'invalid') unless is_uuid_v4($event_id);

    my $as_resultclass = $opts{as_resultclass};

    my $event = $c->cliente_list_events_audio(%opts);
    $c->reply_invalid_param('event_id', 'evento não encontrado') unless $event;

    my $audios = $event->cliente_audios->search_rs(
        {
            'me.duplicated_upload' => 0,
        },
        {
            join       => {'media_upload'},
            '+columns' => {
                'media_upload_bytes' => 'media_upload.file_size',
                (
                    $as_resultclass
                    ? (
                        'media_upload_s3path' => 'media_upload.s3_path',
                      )
                    : ()
                ),
            },
            order_by => [
                {'-asc' => 'me.event_sequence'},
            ]
        }
    );

    my @audios;
    while (my $r = $audios->next) {
        if ($as_resultclass) {
            push @audios, $r;
        }
        else {
            push @audios, {
                (is_test() ? (id => $r->id) : ()),
                event_sequence     => $r->event_sequence(),
                audio_duration     => ceil($r->audio_duration()) . 's',
                cliente_created_at => $r->cliente_created_at->datetime(),
                bytes              => humanize_bytes($r->get_column('media_upload_bytes')),
                waveform           => $r->waveform_base64(),
            };
        }
    }

    return {
        event_id => $event_id,
        audios   => \@audios,
        ($as_resultclass ? (event => $event) : ()),
    };
}

sub cliente_audio_play_inc {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $ids      = $opts{ids}      or confess 'missing ids';

    $user_obj->clientes_audios->search_rs(
        {
            'me.id' => {in => $ids},
        }
    )->update({played_count => \'played_count+1'});
    return 1;
}

1;
