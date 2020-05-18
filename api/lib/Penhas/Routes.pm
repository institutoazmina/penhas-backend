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

    # /me/media
    my $me_media = $me->under('/media')->to(controller => 'Me_Media', action => 'ensure_user_loaded');
    $me_media->post()->to(action => 'upload');

    # /me/tweets
    my $me_tweets = $me->under('/tweets')->to(controller => 'Me_Tweets', action => 'ensure_user_loaded');
    $me_tweets->post()->to(action => 'add');
    $me_tweets->delete()->to(action => 'delete');

    # /timeline/
    my $timeline = $authenticated->under('/timeline')->to(controller => 'Timeline', action => 'ensure_user_loaded');
    $timeline->get()->to(action => 'list');

    # /timeline/:id
    my $timeline_object = $timeline->under(':tweet_id')->to(controller => 'Timeline', action => 'load_object');
    $timeline_object->under('comment')->post()->to(action => 'add_comment');
    $timeline_object->under('like')->post()->to(action => 'add_like');
    $timeline_object->under('report')->post()->to(action => 'add_report');

}

1;
