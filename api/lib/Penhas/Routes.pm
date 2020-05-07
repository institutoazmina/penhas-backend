package Penhas::Routes;
use Mojo::Base -strict;

sub register {
    my $r = shift;

    # PUBLIC ENDPOINTS
    # POST /signup
    $r->route('/signup')->post()->to(controller => 'SignUp', action => 'post');

    # POST /login
    $r->route('/login')->post()->to(controller => 'Login', action => 'post');

    # POST /reset-password
    $r->route('/reset-password/request-new')->post()->to(controller => 'ResetPassword', action => 'request_new');
    $r->route('/reset-password/write-new')->post()->to(controller => 'ResetPassword', action => 'write_new');

    # PRIVATE ENDPOINTS
    my $authenticated = $r->under()->to(controller => 'JWT', action => 'check_user_jwt');

    # POST /logout
    $authenticated->under('/logout')->post()->to(controller => 'Logout', action => 'post');

    # GET /me
    my $me = $authenticated->under('/me')->to(controller => 'Me', action => 'check_and_load');
    $me->get()->to(action => 'find');

    $me->under('/increment-fake-password-usage')->post()->to(action => 'inc_senha_falsa_counter');

    # /me/quiz
    my $me_quiz = $me->under('/quiz')->to(controller => 'Me_Quiz', action => 'ensure_user_loaded');
    $me_quiz->post()->to(action => 'process');

    # /me/tweets
    my $me_tweets = $me->under('/tweets')->to(controller => 'Me_Tweets', action => 'ensure_user_loaded');
    $me_tweets->post()->to(action => 'process');
    $me_tweets->delete()->to(action => 'delete');

    # /tweets/
    my $tweets = $authenticated->under('/tweets')->to(controller => 'Tweets', action => 'ensure_user_loaded');
    $tweets->get()->to(action => 'list');

    # /tweets/:id
    my $tweets_object = $tweets->under(':id')->to(controller => 'Tweets', action => 'load_object');
    $tweets_object->under('comment')->post()->to(action => 'add_comment');
    $tweets_object->under('like')->post()->to(action => 'add_like');

    $tweets_object->get()->to(action => 'detail');


}

1;
