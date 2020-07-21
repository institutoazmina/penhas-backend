package Penhas::Controller::Me_Audios;
use Mojo::Base 'Penhas::Controller::Me_Media';

use DateTime;
use Penhas::Types qw/MobileNumber DateTimeStr/;
use DateTime::Format::Pg;
use Penhas::Logger;

sub audio_upload {
    my $c = shift;

    my $now   = time();
    my $valid = $c->validate_request_params(
        cliente_created_at => {required => 1, type => DateTimeStr, max_length => 100},
        current_time       => {required => 1, type => DateTimeStr, max_length => 100},
    );

    $c->stash('is_audio_upload' => 1, 'return_upload' => 1);

    my $media_upload = Penhas::Controller::Me_Media::upload($c);

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


1;
