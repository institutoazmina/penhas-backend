package Penhas::Routes;
use Mojo::Base -strict;

sub register {
    my $r = shift;

    # PUBLIC ENDPOINTS
    # POST /signup
    $r->post('signup')->to(controller => 'SignUp', action => 'post');

    # POST /login
    $r->post('login')->to(controller => 'Login', action => 'post');

    # POST /reset-password
    $r->post('reset-password/request-new')->to(controller => 'ResetPassword', action => 'request_new');
    $r->post('reset-password/write-new')->to(controller => 'ResetPassword', action => 'write_new');

    # GET /news-redirect
    $r->get('news-redirect')->to(controller => 'News', action => 'redirect');

    # GET /get-proxy
    $r->get('get-proxy')->to(controller => 'MediaDownload', action => 'public_get_proxy');

    # GET /pontos-de-apoio-dados-auxiliares
    $r->get('pontos-de-apoio-dados-auxiliares')->to(controller => 'PontoApoio', action => 'pa_aux_data');

    # GET /pontos-de-apoio
    $r->get('pontos-de-apoio')->to(controller => 'PontoApoio', action => 'pa_list');

    # GET /pontos-de-apoio/$id
    $r->get('pontos-de-apoio/:ponto_apoio_id')->to(controller => 'PontoApoio', action => 'public_pa_detail');

    # quiz anônimo
    my $anon_quiz = $r->under('anon-questionnaires')->to(controller => 'AnonQuestionnaire', action => 'verify_anon_token');
    $anon_quiz->get('config')->to(action => 'aq_config_get');
    $anon_quiz->get()->to(action => 'aq_list_get');
    $anon_quiz->post('new')->to(action => 'aq_list_post');
    $anon_quiz->get('history')->to(action => 'aq_history_get');
    $anon_quiz->post('process')->to(action => 'aq_process_post');

    # Convite de guardiões
    # GET /guardiao?token=
    # POST /guardiao?token=&action=
    my $guardioes = $r->under('web/guardiao')->to(controller => 'Guardiao', action => 'apply_rps');
    $guardioes->get()->to(action => 'get');
    $guardioes->post()->to(action => 'post');

    # GET /web/faq
    my $web = $r->under('web')->to(controller => 'WebFAQ', action => 'apply_rps');
    my $faq = $web->any('faq');
    $faq->get()->to(action => 'webfaq_index');

    # GET /web/faq/_botao_contato_
    $faq->get('_botao_contato_')->to(action => 'webfaq_botao_contato');

    # GET /web/termos-de-uso
    $web->get('termos-de-uso')->to(action => 'web_termos_de_uso');

    # GET /web/politica-privacidade
    $web->get('politica-privacidade')->to(action => 'web_politica_privacidade');

    my $faq_detail = $r->under('web/faq/:faq_id')->to(controller => 'WebFAQ', action => 'apply_rps');
    $faq_detail->get()->to(action => 'webfaq_detail');

    # GET /geocode
    $r->get('geocode')->to(controller => 'PontoApoio', action => 'public_geocode');

    $r->get('ponto-apoio-unlimited')->to(controller => 'PontoApoio', action => 'pa_list_unlimited');

    # Admin endpoints

    # GET /admin/logout
    $r->get('admin/logout')->to(controller => 'Admin::Session', action => 'admin_logout');

    # /admin/login
    $r->post('admin/login')->to(controller => 'Admin::Session', action => 'admin_login');
    $r->get('admin/login')->to(controller => 'Admin::Session', action => 'admin_login_get');

    # /admin
    my $admin = $r->under('admin')->to(controller => 'Admin::Session', action => 'admin_check_authorization');
    $admin->get()->to(action => 'admin_dashboard');
    $admin->get('users')->to(controller => 'Admin::Users', action => 'au_search');
    $admin->get('users-audio-status')->to(controller => 'Admin::Users', action => 'au_audio_status');
    $admin->post('send-message')->to(controller => 'Admin::Users', action => 'ua_send_message');
    $admin->get('user-messages-delete')->to(controller => 'Admin::Users', action => 'ua_delete_message');
    $admin->get('user-messages')->to(controller => 'Admin::Users', action => 'ua_list_messages');
    $admin->post('add-notification')->to(controller => 'Admin::Notifications', action => 'unft_crud');
    $admin->get('add-notification')->to(controller => 'Admin::Notifications', action => 'unft_new_template');
    $admin->get('message-detail')->to(controller => 'Admin::Notifications', action => 'unft_explore');
    $admin->get('notifications')->to(controller => 'Admin::Notifications', action => 'unft_list');
    $admin->get('bignum')->to(controller => 'Admin::BigNum', action => 'abignum_get');
    $admin->post('schedule-delete')->to(controller => 'Admin::Users', action => 'au_schedule_delete');
    $admin->get('unschedule-delete')->to(controller => 'Admin::Users', action => 'au_unschedule_delete');

    $admin->get('ponto-apoio-sugg')->to(controller => 'Admin::PontoApoio', action => 'apa_list');
    $admin->get('analisar-sugestao-ponto-apoio')->to(controller => 'Admin::PontoApoio', action => 'apa_review');
    $admin->post('analisar-sugestao-ponto-apoio')->to(controller => 'Admin::PontoApoio', action => 'apa_review_post');

    # INTERNAL ENDPOINTS
    # GET /maintenance/tick-rss
    my $maintenance = $r->under('maintenance')->to(controller => 'Maintenance', action => 'check_authorization');
    $maintenance->get('tick-rss')->to(controller => 'TickRSS', action => 'tick');

    # GET /maintenance/tags-clear-cache
    $maintenance->get('tags-clear-cache')->to(controller => 'Tags', action => 'clear_cache');

    # GET /maintenance/reindex-all-news
    $maintenance->get('reindex-all-news')->to(controller => 'News', action => 'rebuild_index');

    # GET /maintenance/housekeeping
    $maintenance->get('housekeeping')->to(controller => 'Maintenance', action => 'housekeeping');

    # GET /maintenance/tick-notifications
    $maintenance->get('tick-notifications')->to(controller => 'Maintenance', action => 'tick_notifications');

    # GET /maintenance/fix_tweets_parent_id
    $maintenance->get('fix_tweets_parent_id')->to(controller => 'Maintenance', action => 'fix_tweets_parent_id');


    # PRIVATE ENDPOINTS
    my $authenticated = $r->under()->to(controller => 'JWT', action => 'check_user_jwt');

    # GET /filter-tags
    $authenticated->get('filter-tags')->to(controller => 'Tags', action => 'filter_tags');

    # GET /filter-skills
    $authenticated->get('filter-skills')->to(controller => 'Skills', action => 'filter_skills');

    # POST /logout
    $authenticated->post('logout')->to(controller => 'Logout', action => 'logout_post');

    # POST /reactivate
    $authenticated->post('reactivate')->to(controller => 'Me', action => 'me_reactivate');

    # GET /me
    my $user_loaded = $authenticated->under('')->to(controller => 'Me', action => 'check_and_load');

    # POST /report-profile
    $user_loaded->post('report-profile')->to(controller => 'Me', action => 'me_add_report_profile');

    # POST /block-profile
    $user_loaded->post('block-profile')->to(controller => 'Me', action => 'me_add_block_profile');

    # base do /me
    my $me          = $user_loaded->any('me');
    $me->get()->to(action => 'me_find');
    $me->put()->to(action => 'me_update');
    $me->delete()->to(action => 'me_delete');


    # GET /me/delete-text
    $me->get('delete-text')->to(controller => 'Me', action => 'me_delete_text');

    # GET /me/unread-notif-count // notifications
    $me->get('unread-notif-count')->to(controller => 'Me', action => 'me_unread_notif_count');

    # GET /me/notifications
    $me->get('notifications')->to(controller => 'Me', action => 'me_notifications');

    # POST /me/call-police-pressed
    $me->post('call-police-pressed')->to(action => 'inc_call_police_counter');

    # POST /me/modo-anonimo-toggle
    $me->post('modo-anonimo-toggle')->to(action => 'route_cliente_modo_anonimo_toggle');

    # POST /me/modo-camuflado-toggle
    $me->post('modo-camuflado-toggle')->to(action => 'route_cliente_modo_camuflado_toggle');

    # POST /me/ja-foi-vitima-de-violencia-toggle
    $me->under('ja-foi-vitima-de-violencia-toggle')->post()
      ->to(action => 'route_cliente_ja_foi_vitima_de_violencia_toggle');

    # /me/preferences
    my $me_pref = $me->under('preferences')->to(controller => 'Me_Preferences', action => 'assert_user_perms');
    $me_pref->get()->to(action => 'list_preferences');
    $me_pref->post()->to(action => 'post_preferences');


    # /me/quiz
    my $me_quiz = $me->under('quiz')->to(controller => 'Me_Quiz', action => 'assert_user_perms');
    $me_quiz->post()->to(action => 'process');

    # /me/media
    my $me_media = $me->under('media')->to(controller => 'Me_Media', action => 'assert_user_perms');
    $me_media->post()->to(action => 'upload');

    # /me/tarefas
    my $me_tarefas = $me->under('tarefas')->to(controller => 'Me_Tarefas', action => 'assert_user_perms');
 
    $me_tarefas->get()->to(action => 'me_t_list');
    $me_tarefas->post('sync')->to(action => 'me_t_sync');
    $me_tarefas->post('nova')->to(action => 'me_t_nova');
 

    # /me/tweets
    my $me_tweets = $me->under('tweets')->to(controller => 'Me_Tweets', action => 'assert_user_perms');
    $me_tweets->post()->to(action => 'add');
    $me_tweets->delete()->to(action => 'delete');

    # /me/guardioes
    my $me_guardioes = $me->under('guardioes')->to(controller => 'Me_Guardioes', action => 'assert_user_perms');
    $me_guardioes->post()->to(action => 'upsert');
    $me_guardioes->get()->to(action => 'list');

    my $me_guardioes_object = $me_guardioes->any(':guard_id');
    $me_guardioes_object->delete()->to(action => 'delete');
    $me_guardioes_object->put()->to(action => 'edit');

    # POST /me/guardioes/alert
    $me_guardioes->post('alert')->to(action => 'alert_guards');

    # POST /me/audios
    # GET /me/audios
    # GET /me/audios/:event_id
    my $me_audios = $me->under('audios')->to(controller => 'Me_Audios', action => 'assert_user_perms');
    $me_audios->post()->to(action => 'audio_upload');
    $me_audios->get()->to(action => 'audio_events_list');

    my $me_audios_object = $me_audios->under(':event_id');
    $me_audios_object->get()->to(action => 'audio_events_detail');
    $me_audios_object->delete()->to(action => 'audio_events_delete');
    $me_audios_object->get('download')->to(action => 'audio_download');
    $me_audios_object->post('request-access')->to(action => 'audio_request_access');

    # POST /me/sugerir-pontos-de-apoio
    $me->under('sugerir-pontos-de-apoio')->post()->to(controller => 'PontoApoio', action => 'user_pa_suggest');
    $me->under('sugerir-pontos-de-apoio-completo')->post()->to(controller => 'PontoApoio', action => 'user_pa_suggest_full');

    my $me_pa = $me->under('pontos-de-apoio');

    # GET /me/pontos-de-apoio
    $me_pa->get()->to(controller => 'PontoApoio', action => 'user_pa_list');

    # GET /me/pontos-de-apoio/$id
    $me_pa->get(':ponto_apoio_id')->to(controller => 'PontoApoio', action => 'user_pa_detail');

    # POST /me/avaliar-pontos-de-apoio
    $me->post('avaliar-pontos-de-apoio')->to(controller => 'PontoApoio', action => 'user_pa_rating');


    # GET /me/geocode
    $me->get('geocode')->to(controller => 'PontoApoio', action => 'user_geocode');

    # /timeline/
    my $timeline = $authenticated->under('timeline')->to(controller => 'Timeline', action => 'assert_user_perms');
    $timeline->get()->to(action => 'list');

    # /timeline/:id
    my $timeline_object = $timeline->under(':tweet_id')->to(controller => 'Timeline', action => 'load_object');
    $timeline_object->post('comment')->to(action => 'add_comment');
    $timeline_object->post('like')->to(action => 'add_like');
    $timeline_object->post('report')->to(action => 'add_report');

    # /media-download
    my $media_download
      = $authenticated->under('media-download')->to(controller => 'MediaDownload', action => 'assert_user_perms');
    $media_download->get()->to(action => 'logged_in_get_media');

    # GET /search-users
    $user_loaded->get('search-users')->to(controller => 'Me_Chat', action => 'me_chat_find_users');

    # GET /profile
    $user_loaded->get('profile')->to(controller => 'Me_Chat', action => 'me_load_profile');

    # GET /me/chats
    my $me_chat = $me->under('chats');
    $me_chat->get()->to(controller => 'Me_Chat', action => 'me_chat_sessions');

    # POST /me/chats-session
    $me->post('chats-session')->to(controller => 'Me_Chat', action => 'me_open_session');

    # DELETE /me/chats-session
    $me->delete('chats-session')->to(controller => 'Me_Chat', action => 'me_delete_session');

    # POST /me/chats-messages
    $me->post('chats-messages')->to(controller => 'Me_Chat', action => 'me_send_message');

    # GET /me/chats-messages
    $me->get('chats-messages')->to(controller => 'Me_Chat', action => 'me_list_message');

    # POST /me/manage-blocks
    $me->post('manage-blocks')->to(controller => 'Me_Chat', action => 'me_manage_blocks');


}

1;
