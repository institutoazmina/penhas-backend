package Penhas::Schema2::ResultSet::ClientesAudiosEvento;
use Moose;
use namespace::autoclean;

extends 'DBIx::Class::ResultSet';

sub tick_audios_eventos_status {
    my ($self) = @_;

    $self->search(
        {
            status     => {'!=' => 'free_access_by_admin'},
            created_at => {'<=' => \'DATE_ADD(NOW(), INTERVAL -1 MONTH)'}
        }
    )->update({status => 'hidden'});

    $self->search(
        {
            status     => 'free_access',
            created_at => {'<=' => \'DATE_ADD(NOW(), INTERVAL -3 DAY)'}
        }
    )->update({status => 'blocked_access'});

    return 1;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
