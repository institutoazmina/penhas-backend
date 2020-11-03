package Penhas::Routes;
use Mojo::Base -strict;

sub register {
    my $r = shift;

    # PUBLIC ENDPOINTS
    # POST /signup
    $r->route('signup')->post()->to(controller => 'SignUp', action => 'post');

    # POST /login
    $r->route('login')->post()->to(controller => 'Login', action => 'post');

    # POST /reset-password
    $r->route('reset-password/request-new')->post()->to(controller => 'ResetPassword', action => 'request_new');
    $r->route('reset-password/write-new')->post()->to(controller => 'ResetPassword', action => 'write_new');

    # GET /news-redirect
    $r->route('news-redirect')->get()->to(controller => 'News', action => 'redirect');

    # GET /get-proxy
    $r->route('get-proxy')->get()->to(controller => 'MediaDownload', action => 'public_get_proxy');

    # GET /pontos-de-apoio-dados-auxiliares
    $r->route('pontos-de-apoio-dados-auxiliares')->get()->to(controller => 'PontoApoio', action => 'pa_aux_data');

    # GET /pontos-de-apoio
    $r->route('pontos-de-apoio')->get()->to(controller => 'PontoApoio', action => 'pa_list');

    # GET /pontos-de-apoio/$id
    $r->route('pontos-de-apoio/:ponto_apoio_id')->get()->to(controller => 'PontoApoio', action => 'public_pa_detail');

    # Convite de guardiões
    # GET /guardiao?token=
    # POST /guardiao?token=&action=
    my $guardioes = $r->under('web/guardiao')->to(controller => 'Guardiao', action => 'apply_rps');
    $guardioes->get()->to(action => 'get');
    $guardioes->post()->to(action => 'post');

    # GET /geocode
    $r->route('geocode')->get()->to(controller => 'PontoApoio', action => 'public_geocode');

    # Admin endpoints

    # GET /admin/logout
    $r->route('admin/logout')->get()->to(controller => 'Admin::Session', action => 'admin_logout');

    # POST /admin/login
    $r->route('admin/login')->post()->to(controller => 'Admin::Session', action => 'admin_login');
    $r->route('admin/login')->get()->to(controller => 'Admin::Session', action => 'admin_login_get');

    # /admin
    my $admin = $r->under('admin')->to(controller => 'Admin::Session', action => 'admin_check_authorization');
    $admin->get()->to(action => 'admin_dashboard');
    $admin->route('users')->get->to(controller => 'Admin::Users', action => 'au_search');
    $admin->route('send-message')->post->to(controller => 'Admin::Users', action => 'ua_send_message');
    $admin->route('user-messages')->get->to(controller => 'Admin::Users', action => 'ua_list_messages');

    # INTERNAL ENDPOINTS
    # GET /maintenance/tick-rss
    my $maintenance = $r->under('maintenance')->to(controller => 'Maintenance', action => 'check_authorization');
    $maintenance->route('tick-rss')->get()->to(controller => 'TickRSS', action => 'tick');

    # GET /maintenance/tags-clear-cache
    $maintenance->route('tags-clear-cache')->get()->to(controller => 'Tags', action => 'clear_cache');

    # GET /maintenance/reindex-all-news
    $maintenance->route('reindex-all-news')->get()->to(controller => 'News', action => 'rebuild_index');

    # GET /maintenance/housekeeping
    $maintenance->route('housekeeping')->get()->to(controller => 'Maintenance', action => 'housekeeping');

    # PRIVATE ENDPOINTS
    my $authenticated = $r->under()->to(controller => 'JWT', action => 'check_user_jwt');

    # GET /filter-tags
    $authenticated->under('filter-tags')->get()->to(controller => 'Tags', action => 'filter_tags');

    # GET /filter-skills
    $authenticated->under('filter-skills')->get()->to(controller => 'Skills', action => 'filter_skills');

    # POST /logout
    $authenticated->under('logout')->post()->to(controller => 'Logout', action => 'logout_post');

    # POST /reactivate
    $authenticated->route('reactivate')->post->to(controller => 'Me', action => 'me_reactivate');

    # GET /me
    my $user_loaded = $authenticated->under('')->to(controller => 'Me', action => 'check_and_load');
    my $me          = $user_loaded->route('me');
    $me->get()->to(action => 'me_find');
    $me->put()->to(action => 'me_update');
    $me->delete()->to(action => 'me_delete');

    # GET /me/delete-text
    $me->under('delete-text')->get()->to(controller => 'Me', action => 'me_delete_text');

    # POST /me/call-police-pressed
    $me->under('call-police-pressed')->post()->to(action => 'inc_call_police_counter');

    # POST /me/modo-anonimo-toggle
    $me->under('modo-anonimo-toggle')->post()->to(action => 'route_cliente_modo_anonimo_toggle');

    # POST /me/modo-camuflado-toggle
    $me->under('modo-camuflado-toggle')->post()->to(action => 'route_cliente_modo_camuflado_toggle');

    # POST /me/ja-foi-vitima-de-violencia-toggle
    $me->under('ja-foi-vitima-de-violencia-toggle')->post()->to(action => 'route_cliente_ja_foi_vitima_de_violencia_toggle');

    # /me/quiz
    my $me_quiz = $me->under('quiz')->to(controller => 'Me_Quiz', action => 'assert_user_perms');
    $me_quiz->post()->to(action => 'process');

    # /me/media
    my $me_media = $me->under('media')->to(controller => 'Me_Media', action => 'assert_user_perms');
    $me_media->post()->to(action => 'upload');

    # /me/tweets
    my $me_tweets = $me->under('tweets')->to(controller => 'Me_Tweets', action => 'assert_user_perms');
    $me_tweets->post()->to(action => 'add');
    $me_tweets->delete()->to(action => 'delete');

    # /me/guardioes
    my $me_guardioes = $me->under('guardioes')->to(controller => 'Me_Guardioes', action => 'assert_user_perms');
    $me_guardioes->post()->to(action => 'upsert');
    $me_guardioes->get()->to(action => 'list');

    my $me_guardioes_object = $me_guardioes->under(':guard_id');
    $me_guardioes_object->delete()->to(action => 'delete');
    $me_guardioes_object->put()->to(action => 'edit');

    # POST /me/guardioes/alert
    $me_guardioes->under('alert')->post()->to(action => 'alert_guards');

    # POST /me/audios
    # GET /me/audios
    # GET /me/audios/:event_id
    my $me_audios = $me->under('audios')->to(controller => 'Me_Audios', action => 'assert_user_perms');
    $me_audios->post()->to(action => 'audio_upload');
    $me_audios->get()->to(action => 'audio_events_list');

    my $me_audios_object = $me_audios->under(':event_id');
    $me_audios_object->get()->to(action => 'audio_events_detail');
    $me_audios_object->delete()->to(action => 'audio_events_delete');
    $me_audios_object->route('download')->get()->to(action => 'audio_download');
    $me_audios_object->route('request-access')->post()->to(action => 'audio_request_access');

    # POST /me/sugerir-pontos-de-apoio
    $me->under('sugerir-pontos-de-apoio')->post()->to(controller => 'PontoApoio', action => 'user_pa_suggest');

    my $me_pa = $me->under('pontos-de-apoio');

    # GET /me/pontos-de-apoio
    $me_pa->get()->to(controller => 'PontoApoio', action => 'user_pa_list');

    # GET /me/pontos-de-apoio/$id
    $me_pa->under(':ponto_apoio_id')->get()->to(controller => 'PontoApoio', action => 'user_pa_detail');

    # POST /me/avaliar-pontos-de-apoio
    $me->under('avaliar-pontos-de-apoio')->post()->to(controller => 'PontoApoio', action => 'user_pa_rating');


    # GET /me/geocode
    $me->under('geocode')->get()->to(controller => 'PontoApoio', action => 'user_geocode');

    # /timeline/
    my $timeline = $authenticated->under('timeline')->to(controller => 'Timeline', action => 'assert_user_perms');
    $timeline->get()->to(action => 'list');

    # /timeline/:id
    my $timeline_object = $timeline->under(':tweet_id')->to(controller => 'Timeline', action => 'load_object');
    $timeline_object->under('comment')->post()->to(action => 'add_comment');
    $timeline_object->under('like')->post()->to(action => 'add_like');
    $timeline_object->under('report')->post()->to(action => 'add_report');

    # /media-download
    my $media_download
      = $authenticated->under('media-download')->to(controller => 'MediaDownload', action => 'assert_user_perms');
    $media_download->get()->to(action => 'logged_in_get_media');

    # GET /search-users
    $user_loaded->under('search-users')->get()->to(controller => 'Me_Chat', action => 'me_chat_find_users');

    # GET /profile
    $user_loaded->under('profile')->get()->to(controller => 'Me_Chat', action => 'me_load_profile');

    # GET /me/chats
    my $me_chat = $me->under('chats');
    $me_chat->get()->to(controller => 'Me_Chat', action => 'me_chat_sessions');

    # POST /me/chats-session
    $me->route('chats-session')->post()->to(controller => 'Me_Chat', action => 'me_open_session');

    # DELETE /me/chats-session
    $me->route('chats-session')->delete()->to(controller => 'Me_Chat', action => 'me_delete_session');

    # POST /me/chats-messages
    $me->route('chats-messages')->post()->to(controller => 'Me_Chat', action => 'me_send_message');

    # GET /me/chats-messages
    $me->route('chats-messages')->get()->to(controller => 'Me_Chat', action => 'me_list_message');

    # POST /me/manage-blocks
    $me->route('manage-blocks')->post()->to(controller => 'Me_Chat', action => 'me_manage_blocks');


}

1;
