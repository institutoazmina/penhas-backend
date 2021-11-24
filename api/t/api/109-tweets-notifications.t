use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;

my $t = test_instance;

use Penhas::Minion::Tasks::NewNotification;

my ($cliente_id, $session, $user) = get_new_user();
on_scope_exit { user_cleanup(user_id => $cliente_id); };

my ($cliente_id2, $session2, $user2) = get_new_user();
on_scope_exit { user_cleanup(user_id => $cliente_id2); };

my ($cliente_id3, $session3, $user3) = get_new_user();
on_scope_exit { user_cleanup(user_id => $cliente_id3); };

my ($cliente_id4, $session4, $user4) = get_new_user();
on_scope_exit { user_cleanup(user_id => $cliente_id4); };

$ENV{FILTER_QUESTIONNAIRE_IDS} = '9999';
$ENV{SKIP_END_NEWS}            = '1';
delete $ENV{SUBSUBCOMENT_DISABLED};

$Penhas::Helpers::Timeline::ForceFilterClientes = [$cliente_id, $cliente_id2, $cliente_id3, $cliente_id4];

my $tweet_rs = app->schema2->resultset('Tweet');
my $job      = Minion::Job->new(
    id     => fake_int(1, 99)->(),
    minion => $t->app->minion,
    task   => 'testmocked',
    notes  => {hello => 'mock'}
);

$ENV{NOTIFICATIONS_ENABLED} = 1;
my $res = $t->post_ok(
    '/me/tweets',
    {'x-api-key' => $session},
    form => {
        content => 'root tweet',
    }
)->status_is(200)->tx->res->json;
my $tweet_id = $res->{id};

db_transaction2 {
    &_test_notifications(tweet_id => $tweet_id);
};

db_transaction2 {
    &_test_notification_paging(tweet_id => $tweet_id);
};

done_testing();

exit;

sub run_notification_job {
    ok(
        Penhas::Minion::Tasks::NewNotification::new_notification(
            $job, test_get_minion_args_job($ENV{LAST_NTF_COMMENT_JOB_ID})
        ),
        'job'
    );
}

sub _test_notifications {
    my (%opts) = @_;
    my $tweet_id = $opts{tweet_id};

    is $ENV{LAST_NTF_COMMENT_JOB_ID}, undef, 'no LAST_NTF_COMMENT_JOB_ID yet';

    my $comment = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'comment'),
        {'x-api-key' => $session},
        form => {content => 'comment from owner'}
    )->status_is(200)->tx->res->json;
    is $comment->{meta}{tweet_depth_test_only}, 2, '2nd level [subcoment]';

    is $user->notification_logs->count, 0, 'no logs';
    run_notification_job();

    is $user->notification_logs->count, 0, 'no notifications about ownself';
    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';

    my $comment_user2 = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'comment'),
        {'x-api-key' => $session2},
        form => {content => 'comment from other'}
    )->status_is(200)->tx->res->json;
    is $comment_user2->{meta}{tweet_depth_test_only}, 2, '2nd level [subcoment]';

    is $user->notification_logs->count, 0, 'no logs yet, no job run!';
    run_notification_job();

    is $user->notification_logs->count, 1, 'one notification about the other comment';
    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';
    is $user2->notification_logs->count, 0, 'no notification yet';

    my $subcomment_user = $t->post_ok(
        (join '/', '/timeline', $comment_user2->{id}, 'comment'),
        {'x-api-key' => $session},
        form => {content => 'subcomment from post owner'}
    )->status_is(200)->tx->res->json;
    is $subcomment_user->{meta}{tweet_depth_test_only}, 3, '3nd level [sub-subcoment]';

    is $user->notification_logs->count, 1, 'no logs yet, no job run!';
    run_notification_job();

    is $user->notification_logs->count, 1, 'still just one notification';
    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';
    is $user2->notification_logs->count, 1, 'now there is one notification for the user 2';


    my $subcomment_user3 = $t->post_ok(
        (join '/', '/timeline', $comment_user2->{id}, 'comment'),
        {'x-api-key' => $session3},
        form => {content => 'subcomment from yet another user'}
    )->status_is(200)->tx->res->json;
    is $subcomment_user3->{meta}{tweet_depth_test_only}, 3, '3nd level [sub-subcoment]';

    is $user->notification_logs->count, 1, 'no logs yet, no job run!';
    run_notification_job();

    is $user->notification_logs->count, 2, 'one new notification';
    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';
    is $user2->notification_logs->count, 2, 'other user too gets an notification';


    my $comment_user4 = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'comment'),
        {'x-api-key' => $session4},
        form => {content => 'comment from yet another user 4'}
    )->status_is(200)->tx->res->json;
    is $comment_user4->{meta}{tweet_depth_test_only}, 2, '2nd level [sub-subcoment]';

    run_notification_job();

    is $user->notification_logs->count,  3, 'one new notification';
    is $user2->notification_logs->count, 3, 'one new notification';
    is $user3->notification_logs->count, 0, 'no notification for user 3 (he is inside a subcomment)';
    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';


    my $comment_user3 = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'comment'),
        {'x-api-key' => $session3},
        form => {content => 'comment from yet another user 3'}
    )->status_is(200)->tx->res->json;
    is $comment_user3->{meta}{tweet_depth_test_only}, 2, '2nd level [sub-subcoment]';

    is $user4->notification_logs->count, 0, 'no notification yet';

    run_notification_job();

    is $user->notification_logs->count,  4, 'one new notification';
    is $user2->notification_logs->count, 4, 'one new notification';
    is $user3->notification_logs->count, 0, 'no notification for user 3 (he is commenting)';
    is $user4->notification_logs->count, 1, 'new notification for user 4';
    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';


    # now test permissions
    # desliga os notification sobre os comentarios no post
    $t->post_ok(
        '/me/preferences', {'x-api-key' => $session},
        form => {
            'NOTIFY_COMMENTS_POSTS_CREATED' => 0,
        }
    )->status_is(204);
    $t->get_ok(
        '/me/preferences', {'x-api-key' => $session},
    );

    # e desliga os notifications sobre comentarios no user 4
    $t->post_ok(
        '/me/preferences', {'x-api-key' => $session4},
        form => {
            'NOTIFY_COMMENTS_POSTS_COMMENTED' => 0,
        }
    )->status_is(204);

    my $comment_user3_again = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'comment'),
        {'x-api-key' => $session3},
        form => {content => 'comment from yet another user 3 again'}
    )->status_is(200)->tx->res->json;
    is $comment_user3_again->{meta}{tweet_depth_test_only}, 2, '2nd level [sub-subcoment]';

    is $user4->notification_logs->count, 1, 'just one notification from before';

    run_notification_job();

    is $user->notification_logs->count,  4, 'no new notifications';
    is $user2->notification_logs->count, 5, 'one new notification';
    is $user3->notification_logs->count, 0, 'no notification for user 3 (he is commenting)';
    is $user4->notification_logs->count, 1, 'no new notification for user 4';
    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';

}

sub _test_notification_paging {


    my $comment2 = $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'comment'),
        {'x-api-key' => $session2},
        form => {content => 'comment'}
    )->status_is(200)->tx->res->json;

    run_notification_job();

    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';
    is $user->notification_logs->count, 1, 'only one notification, yay!';

    is $ENV{LAST_NTF_LIKE_JOB_ID}, undef, 'no LAST_NTF_LIKE_JOB_ID yet';
    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'like'),
        {'x-api-key' => $session},
    )->status_is(200);
    trace_popall;
    ok(
        Penhas::Minion::Tasks::NewNotification::new_notification(
            $job, test_get_minion_args_job($ENV{LAST_NTF_LIKE_JOB_ID})
        ),
        'job'
    );
    is trace_popall, 'minion:new_notification,new_like', 'expected code path';
    is $user->notification_logs->count, 1, 'no notifications (same user liked)';

    $t->post_ok(
        (join '/', '/timeline', $tweet_id, 'like'),
        {'x-api-key' => $session2},
    )->status_is(200);
    trace_popall;
    ok(
        Penhas::Minion::Tasks::NewNotification::new_notification(
            $job, test_get_minion_args_job($ENV{LAST_NTF_LIKE_JOB_ID})
        ),
        'job'
    );
    is trace_popall, 'minion:new_notification,new_like,NOTIFY_LIKES_POSTS_CREATED,1', 'expected code path';
    is $user->notification_logs->count, 2, 'new notification';


    my $comment2_subcomment = $t->post_ok(
        (join '/', '/timeline', $comment2->{id}, 'comment'),
        {'x-api-key' => $session3},
        form => {content => 'subcomment'}
    )->status_is(200)->tx->res->json;

    is $comment2_subcomment->{meta}{tweet_depth_test_only}, 3, '3nd level [comment of a comment]';
    is $comment2_subcomment->{meta}{can_reply},             0, '3nd level is not allowed to comment';

    trace_popall;
    run_notification_job();
    is trace_popall, 'minion:new_notification,new_comment', 'expected code path';
    is $user->notification_logs->count, 3, 'new notifications (user 3 posted a subcomment)';

    $t->post_ok(
        (join '/', '/timeline', $comment2_subcomment->{id}, 'like'),
        {'x-api-key' => $session2},
    )->status_is(200);
    is $user3->notification_logs->count, 0, 'no notifications yet';
    trace_popall;
    ok(
        Penhas::Minion::Tasks::NewNotification::new_notification(
            $job, test_get_minion_args_job($ENV{LAST_NTF_LIKE_JOB_ID})
        ),
        'job'
    );
    is trace_popall, 'minion:new_notification,new_like,NOTIFY_LIKES_POSTS_COMMENTED,1', 'expected code path';
    is $user3->notification_logs->count, 1, 'notification for new like';

    $t->get_ok(
        ('/me/unread-notif-count'),
        {'x-api-key' => $session},
    )->status_is(200)->json_is('/count', 3, '3 unread notifications');

    $t->get_ok(
        ('/me/notifications'),
        {'x-api-key' => $session},
        form => {rows => 2}
      )->status_is(200, 'notifications page1')    #
      ->json_is('/has_more', 1, 'has more')                                   #
      ->json_has('/next_page', 'next_page')                                   #
      ->json_is('/rows/0/content', '❝subcomment❞ na publicação ❝comment❞')    #
      ->json_is('/rows/0/title',   'comentou sua publicação')                 #
      ->json_is('/rows/0/name',    'xpto c')                                  #
      ->json_like('/rows/0/icon', qr/2\.svg/, 'icon ok')                      #
      ->json_is('/rows/1/content', 'root tweet')                              #
      ->json_is('/rows/1/name',    'xpto b')                                  #
      ->json_like('/rows/1/icon', qr/3\.svg/, 'icon ok')                      #
      ->json_is('/rows/1/title', 'curtiu sua publicação')                     #
      ->json_is('/rows/2', undef, 'just 2 rows asked');

    $t->get_ok(
        ('/me/notifications'),
        {'x-api-key' => $session},
        form => {next_page => last_tx_json->{next_page}}
      )->status_is(200, 'notifications next_page')                            #
      ->json_is('/has_more',       0,     'has more')                         #
      ->json_is('/next_page',      undef, 'next_page not defined')            #
      ->json_is('/rows/0/content', '❝comment❞ na publicação ❝root tweet❞') #
      ->json_is('/rows/0/title',   'comentou sua publicação');

    $t->get_ok(
        ('/me/unread-notif-count'),
        {'x-api-key' => $session},
    )->status_is(200)->json_is('/count', 0, '0 unread notifications');


}
