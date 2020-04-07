package Mojolicious::Plugin::SimpleAuthentication;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $args) = @_;

    $args ||= {};

    ref $args->{validate_user} eq 'CODE' or die __PACKAGE__ . ": 'validate_user' should be a subroutine ref\n";

    my $stash_key       = $args->{stash_key}       || '__authentication__';
    my $current_user_fn = $args->{current_user_fn} || 'current_user';
    my $validate_user_cb = $args->{validate_user};

    $app->helper(
        authenticate => sub {
            my $c = shift;

            my $user = $validate_user_cb->($c, @_);

            return 1 if ref $user;
        }
    );
}

1;
