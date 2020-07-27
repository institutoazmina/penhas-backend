package Penhas::Controller::Me_Audios;
use Mojo::Base 'Penhas::Controller::Me_Media';

use DateTime;
use Penhas::Types qw/MobileNumber DateTimeStr/;
use DateTime::Format::Pg;
use Penhas::Logger;
use Penhas::Utils;

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

1;
