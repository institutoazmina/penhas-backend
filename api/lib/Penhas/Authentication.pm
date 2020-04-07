package Penhas::Authentication;
use strict;
use warnings;
use Mojo::UserAgent;

sub validate_user {
    my ($c, $email, $password) = @_;

    my $user = $c->schema->resultset('User')->search({'me.email' => $email})->next;

    if (ref $user) {
        if ($user->check_password($password)) {
            return $user;
        }
    }
    return;
}

1;
