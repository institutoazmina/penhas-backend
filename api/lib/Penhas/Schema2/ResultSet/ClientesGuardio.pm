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

sub used_invites_count {
    my ($self) = @_;

    return $self->search(
        {
            status     => {in => [qw/pending accepted expired_for_not_use refused/]},
            deleted_at => undef,
        }
    )->count;
}

sub max_invites_count {
    return $ENV{MAX_GUARDS_INVITES} || 5;
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
