package Penhas::Controller::Me_Audios;
use Mojo::Base 'Penhas::Controller::Me_Media';

use DateTime;
use Penhas::Types qw/MobileNumber DateTimeStr/;

sub audio_upload {
    my $c = shift;

    my $valid = $c->validate_request_params(
        cliente_created_at => {required => 1, type => DateTimeStr, max_length => 100},
        current_time       => {required => 1, type => DateTimeStr, max_length => 100},
    );

    $c->stash('is_audio_upload' => 1, 'return_upload' => 1);

    my $media_upload = Penhas::Controller::Me_Media::upload($c);

use DDP; p $media_upload;
    my $ret = {id => $media_upload->id};


    return $c->render(
        json   => $ret,
        status => 200,
    );
}


1;
