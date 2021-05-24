package Penhas::Schema2::ResultSet::ClientesAudiosEvento;
use Moose;
use namespace::autoclean;

extends 'DBIx::Class::ResultSet';

sub tick_audios_eventos_status {
    my ($self) = @_;

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
