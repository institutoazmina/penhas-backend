package Penhas::Routes;
use Mojo::Base -strict;

sub register {
    my $r = shift;

    # PUBLIC ENDPOINTS
    # /signup
    my $signup = $r->route('/signup');
    $signup->post()->to(controller => 'SignUp', action => 'post');

}

1;
