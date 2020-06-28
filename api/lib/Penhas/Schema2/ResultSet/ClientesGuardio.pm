package Penhas::Schema2::ResultSet::ClientesGuardio;
use Moose;
use namespace::autoclean;

extends 'DBIx::Class::ResultSet';

sub expires_pending_invites {
    my ($self) = @_;

    $self->search(
        {
            status     => 'pending',
            expires_at => {
                '<=' => \'NOW()',
            },
        }
    )->update({status => 'expired_for_not_use'});
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
