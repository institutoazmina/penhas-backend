package Penhas::Schema2::ResultSet::ClientesAudiosEvento;
use Moose;
use namespace::autoclean;
use Penhas::Logger;
extends 'DBIx::Class::ResultSet';

sub tick_audios_eventos_status {
    my ($self) = @_;

    # 5 anos pra apagar
    my $delete_rs = $self->search(
        {
            status     => {'!=' => 'delete_from_s3'},
            created_at => {'<=' => \"NOW() + INTERVAL '-5 YEARS'"}
        }
    );

    my $minion = Penhas::Minion->instance;
    while (my $r = $delete_rs->next) {

        my $job_id = $minion->enqueue(
            'delete_audio',
            [
                $r->id,
            ] => {
                attempts => 5,
            }
        );

        slog_info('Adding job delete_user %s, job id %s', $r->id, $job_id);
        $r->update({status => 'delete_from_s3'});
        $ENV{LAST_AUDIO_DELETE_JOB_ID} = $job_id;
    }

    # 40 dias pra quem liberou manualmente
    $self->search(
        {
            status     => 'free_access_by_admin',
            created_at => {'<=' => \"NOW() + INTERVAL '-40 DAY'"}
        }
    )->update({status => 'hidden'});

    # 30 dias pra outros
    $self->search(
        {
            status     => 'blocked_access',
            created_at => {'<=' => \"NOW() + INTERVAL '-30 DAY'"}
        }
    )->update({status => 'hidden'});

    # 3 dias move pro blocked
    $self->search(
        {
            status     => 'free_access',
            created_at => {'<=' => \"NOW() + INTERVAL '-3 DAY'"}
        }
    )->update({status => 'blocked_access'});

    return 1;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
