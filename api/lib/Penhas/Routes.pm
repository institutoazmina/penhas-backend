package Penhas::Routes;
use Mojo::Base -strict;

sub register {
    my $r = shift;

    # PUBLIC ENDPOINTS
    # /signup
    my $signup = $r->route('/signup');
    $signup->post()->to(controller => 'SignUp', action => 'post');

    # PRIVATE ENDPOINTS
    my $authenticated = $r->under()->to(controller => 'JWT', action => 'check_user_jwt');

    # POST /logout
    $authenticated->under('/logout')->post()->to(controller => 'Logout', action => 'post');

    # GET /me
    my $me = $authenticated->under('/me')->to(controller => 'Me', action => 'check_and_load');
    $me->get()->to(action => 'find');



}

1;
