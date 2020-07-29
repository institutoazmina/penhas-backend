package Penhas::Controller::Me_Audios;
use Mojo::Base 'Penhas::Controller::Me_Media';
use utf8;
use DateTime;
use Penhas::Types qw/MobileNumber DateTimeStr IntList/;
use DateTime::Format::Pg;
use Penhas::Logger;
use Penhas::Utils;
use MojoX::InsistentPromise;
use Digest::SHA qw(sha1_hex);
use Encode;
use IPC::Run3;

sub audio_upload {
    my $c = shift;

    my $now   = time();
    my $valid = $c->validate_request_params(
        cliente_created_at => {required => 1, type => DateTimeStr, max_length => 100},
        current_time       => {required => 1, type => DateTimeStr, max_length => 100},
        event_id           => {required => 1, type => 'Str',       max_length => 36},
        event_sequence     => {required => 1, type => 'Int',       max_length => 6},
    );

    $c->reply_invalid_param('event_id',       'invalid') unless is_uuid_v4($valid->{event_id});
    $c->reply_invalid_param('event_sequence', 'invalid')
      if $valid->{event_sequence} < 0 || $valid->{event_sequence} > 1000;

    $valid->{event_id} = lc $valid->{event_id};
    $c->stash('is_audio_upload' => 1, 'return_upload' => 1, 'extract_waveform' => 1);

    my $media_upload = Penhas::Controller::Me_Media::upload($c);

    $valid->{waveform}       = $c->stash('waveform');
    $valid->{audio_duration} = $c->stash('audio_duration');

    my $current_time = DateTime::Format::Pg->parse_datetime($valid->{current_time});
    my $created_at   = DateTime::Format::Pg->parse_datetime($valid->{cliente_created_at});

    my $diff = $now - $current_time->epoch;

    if (abs($diff) > 10) {
        $valid->{cliente_created_at} = $created_at->clone->add(seconds => $diff)->datetime(' ');
        slog_info(
            'Time sent from client is too different, ajusting time. client current_time=%s, cliente_created_at=%s server now=%s (ajusting for %s seconds); new cliente_created_at %s',
            $current_time->datetime,
            $created_at->datetime,
            $now,
            $diff,
            $valid->{cliente_created_at}
        );
    }

    my $ret = $c->cliente_new_audio(
        %$valid,
        media_upload => $media_upload,
        user_obj     => $c->stash('user_obj')
    );

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

sub audio_events_list {
    my $c = shift;

    my $ret = $c->cliente_list_events_audio(user_obj => $c->stash('user_obj'));

    return $c->render(
        json   => $ret,
        status => 200,
    );

}

sub audio_events_detail {
    my $c = shift;

    return $c->render(
        json => $c->cliente_detail_events_audio(
            event_id => $c->stash('event_id'),
            user_obj => $c->stash('user_obj'),
        ),
        status => 200,
    );
}

sub audio_events_delete {
    my $c = shift;

    $c->cliente_delete_events_audio(
        event_id => $c->stash('event_id'),
        user_obj => $c->stash('user_obj'),
    );

    return $c->rendered(204);
}

sub audio_download {
    my $c = shift;

    my $valid = $c->validate_request_params(
        audio_sequences => {required => 1, type => 'Str', max_length => 5000},
    );

    my @audio_sequences;
    if ($valid->{audio_sequences} ne 'all') {
        $c->validate_request_params(audio_sequences => {type => IntList});
        @audio_sequences = split /,/, $valid->{audio_sequences};
    }

    my $audios = $c->cliente_detail_events_audio(
        event_id       => $c->stash('event_id'),
        user_obj       => $c->stash('user_obj'),
        as_resultclass => 1,
    );

    my @downloads_rows;
    if (@audio_sequences) {
        my %exists = map { $_->event_sequence() => $_ } $audios->{audios}->@*;

        # faz na ordem, pois o concat sera na ordem do @downloads_rows
        foreach my $seq (sort { $a <=> $b } @audio_sequences) {
            $c->reply_invalid_param('audio_sequences', sprintf('áudio número %d não foi encontrado', $seq))
              unless exists $exists{$seq};

            push @downloads_rows, $exists{$seq};
        }
    }
    else {

        # ja vem ordenado do banco
        @downloads_rows = map {$_} $audios->{audios}->@*;
    }

    $c->cliente_audio_play_inc(
        user_obj => $c->stash('user_obj'),
        ids      => [map { $_->id() } @downloads_rows],
    );

    my @concat_files;
    my @promises;
    foreach my $row (@downloads_rows) {
        my $filename = $ENV{TMP_AUDIO_DIR} . '/' . join('-', $audios->{event_id}, $row->id . '.aac');
        push @concat_files, $filename;

        next if -e $filename;

        my ($insistent, $get_p) = MojoX::InsistentPromise->new(
            max_fail     => is_test() ? 2 : 7,
            check_sucess => sub {
                my ($tx, $cliente_audio_id) = @_;
                return !$tx->res->is_error && $tx->res->code == 200;
            },
            init => sub {
                log_trace('download');
                return $c->ua->get_p($row->get_column('media_upload_s3path'));
            },
            id => $row->id
        );
        push @promises, $get_p;

        $get_p->then(
            sub {
                my ($response) = @_;
                slog_debug('saving cliente_audio_id %d to %s', $row->id, $filename);
                $response->res->save_to($filename);
            }
        )->catch(
            sub {
                my ($errmsg, $cliente_audio_id, $response) = @_;
                if (UNIVERSAL::can($response, 'res')) {
                    slog_error(
                        "Failed download cliente_audio_id %s with response=%s",
                        $cliente_audio_id, $response->res->to_string
                    );
                }
                else {
                    slog_error(
                        'Failed download cliente_audio_id %s with error=%s',
                        $cliente_audio_id, $c->dumper([$errmsg, $response])
                    );
                }
            }
        )->finally(
            sub {
                undef $insistent;
            }
        );
    }

    # se precisa baixar alguma coisa, nao vai dar pra responder agora
    if (@promises) {
        slog_debug('there is some files to download... waiting...');
        $c->render_later;
        Mojo::Promise->all(@promises)->then(
            sub {
                slog_debug('all files downloaded, running ffmpeg to concat...');

                &_concat_audio_files($c, files => \@concat_files);

            }
        )->catch(
            sub {
                my @err = @_;
                log_error($c->dumper(@err));

                $c->render(
                    json => {
                        error => 'download_error',
                        message =>
                          'Não foi possível baixar todos os arquivos neste momento 😞. Tente novamente mais tarde.'
                    },
                    status => 400,
                );
            }
        );
    }
    else {
        log_trace('cached');
        slog_debug('all files were downloaded already, running ffmpeg to concat...');

        # faz o concat (ou não) e segue com o download
        &_concat_audio_files($c, files => \@concat_files);

    }


    return 1;
}

sub _concat_audio_files {
    my ($c, %opts) = @_;

    my @files = $opts{files}->@*;
    die 'missing @files' unless scalar @files;

    foreach my $filename (@files) {

        if (!-e $filename) {
            slog_error('%s file not found!', $filename);
            $c->render(
                json => {
                    error   => 'audio_file_not_exists',
                    message => 'Não foi possível abrir arquivos, tente novamente mais tarde.'
                },
                status => 500,
            );
            return 1;
        }
        else {
            slog_debug('file %s exists!', $filename);
        }
    }

    my $files_concated = join '|', @files;
    my $outfile        = $ENV{TMP_AUDIO_DIR} . '/' . (sha1_hex(encode_utf8($files_concated)) . '.aac');

    if (-e $outfile) {

        # esta cached
        $c->reply->file($outfile);
    }
    elsif (@files == 1) {

        # nao precisa concat, pq so tem 1 arquivo
        $c->reply->file($files[0]);
    }
    else {
        log_info("running concat $files_concated to $outfile");


        my @ffmpeg = ();
        push @ffmpeg, qw(ffmpeg -i);
        push @ffmpeg, 'concat:' . $files_concated;
        push @ffmpeg, qw(-acodec copy);
        push @ffmpeg, $outfile;

        my $stderr = '';
        my $stdout = '';

        eval { run3 \@ffmpeg, \undef, \$stdout, \$stderr; };

        if ($@ || -z $files_concated) {
            log_error("concat audio FAILED: $@ - $stderr $stdout");

            $c->render(
                json => {
                    error => 'concat_failed',
                    message =>
                      'Não foi possível juntar os áudios, tente novamente mais tarde, ou baixe cada arquivo separadamente.',
                },
                status => 500,
            );
        }

        log_trace('ffmpeg-concat');

        $c->reply->file($outfile);
    }
}

1;
