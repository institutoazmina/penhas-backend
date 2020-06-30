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

    # GET /news-redirect
    $r->route('news-redirect')->get()->to(controller => 'News', action => 'redirect');

    # GET /get-proxy
    $r->route('get-proxy')->get()->to(controller => 'MediaDownload', action => 'public_get_proxy');

    # INTERNAL ENDPOINTS
    # GET /maintenance/tick-rss
    my $maintenance = $r->under('maintenance')->to(controller => 'Maintenance', action => 'check_authorization');
    $maintenance->route('tick-rss')->get()->to(controller => 'TickRSS', action => 'tick');

    # GET /maintenance/tags-clear-cache
    $maintenance->route('tags-clear-cache')->get()->to(controller => 'Tags', action => 'clear_cache');

    # GET /maintenance/reindex-all-news
    $maintenance->route('reindex-all-news')->get()->to(controller => 'News', action => 'rebuild_index');

    # PRIVATE ENDPOINTS
    my $authenticated = $r->under()->to(controller => 'JWT', action => 'check_user_jwt');

    # GET /filter-tags
    $authenticated->under('/filter-tags')->get()->to(controller => 'Tags', action => 'filter_tags');

    # POST /logout
    $authenticated->under('/logout')->post()->to(controller => 'Logout', action => 'post');

    # GET /me
    my $me = $authenticated->under('/me')->to(controller => 'Me', action => 'check_and_load');
    $me->get()->to(action => 'find');

    $me->under('/increment-fake-password-usage')->post()->to(action => 'inc_senha_falsa_counter');

    # /me/quiz
    my $me_quiz = $me->under('/quiz')->to(controller => 'Me_Quiz', action => 'assert_user_perms');
    $me_quiz->post()->to(action => 'process');

    # /me/media
    my $me_media = $me->under('/media')->to(controller => 'Me_Media', action => 'assert_user_perms');
    $me_media->post()->to(action => 'upload');

    # /me/tweets
    my $me_tweets = $me->under('/tweets')->to(controller => 'Me_Tweets', action => 'assert_user_perms');
    $me_tweets->post()->to(action => 'add');
    $me_tweets->delete()->to(action => 'delete');

    # /me/guardioes
    my $me_guardioes = $me->under('/guardioes')->to(controller => 'Me_Guardioes', action => 'assert_user_perms');
    $me_guardioes->post()->to(action => 'upsert');

    my $me_guardioes_object = $me_guardioes->under(':guard_id');
    $me_guardioes_object->delete()->to(action => 'delete');
    $me_guardioes_object->put()->to(action => 'edit');


    # /timeline/
    my $timeline = $authenticated->under('/timeline')->to(controller => 'Timeline', action => 'assert_user_perms');
    $timeline->get()->to(action => 'list');

    # /timeline/:id
    my $timeline_object = $timeline->under(':tweet_id')->to(controller => 'Timeline', action => 'load_object');
    $timeline_object->under('comment')->post()->to(action => 'add_comment');
    $timeline_object->under('like')->post()->to(action => 'add_like');
    $timeline_object->under('report')->post()->to(action => 'add_report');

    # /media-download
    my $media_download
      = $authenticated->under('/media-download')->to(controller => 'MediaDownload', action => 'assert_user_perms');
    $media_download->get()->to(action => 'logged_in_get_media');


}

1;
