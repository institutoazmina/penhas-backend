package Penhas::Routes;
use Mojo::Base -strict;

sub register {
    my $r = shift;

    # PUBLIC ENDPOINTS
    # POST /signup
    $r->route('/signup')->post()->to(controller => 'SignUp', action => 'post');

    # POST /login
    $r->route('/login')->post()->to(controller => 'Login', action => 'post');

    # PRIVATE ENDPOINTS
    my $authenticated = $r->under()->to(controller => 'JWT', action => 'check_user_jwt');

    # POST /logout
    $authenticated->under('/logout')->post()->to(controller => 'Logout', action => 'post');

    # GET /me
    my $me = $authenticated->under('/me')->to(controller => 'Me', action => 'check_and_load');
    $me->get()->to(action => 'find');

    $me->under('/increment-fake-password-usage')->post()->to(action => 'inc_senha_falsa_counter');




}

1;
