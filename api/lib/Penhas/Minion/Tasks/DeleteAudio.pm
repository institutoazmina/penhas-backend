package Penhas::Minion::Tasks::DeleteAudio;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Digest::MD5 qw/md5_hex/;
use Penhas::Uploader;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(delete_audio => \&delete_audio);
}

sub delete_audio {
    my ($job, $audio_evento_id) = @_;

    log_trace("minion:delete_audio", $audio_evento_id);
    my $schema2 = $job->app->schema2;

    my $logger = $job->app->log;

    my $event = $schema2->resultset('ClientesAudiosEvento')->find($audio_evento_id);
    goto OK if !$event;
    my @audios = map {$_} $event->cliente_audios->get_column('media_upload_id')->all;

    my $s3       = Penhas::Uploader->new();
    my $media_rs = $schema2->resultset('MediaUpload')->search({id => {'in' => \@audios}});

    my $sum_deleted_bytes = 0;
    while (my $r = $media_rs->next) {

        $s3->remove_by_uri($r->s3_path);
        $s3->remove_by_uri($r->s3_path_avatar) if $r->s3_path_avatar;

        $sum_deleted_bytes += $r->file_size;
        $sum_deleted_bytes += $r->file_size_avatar if $r->file_size_avatar;
        $r->delete;
    }
    $logger->info("s3 deleted $sum_deleted_bytes bytes");

    $schema2->txn_do(
        sub {
            $event->cliente_audios->delete;
            $event->delete;
        }
    );

  OK:
    return $job->finish(1);

}

1;
