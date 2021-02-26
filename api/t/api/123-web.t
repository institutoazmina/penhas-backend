use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use DateTime;
use Penhas::Test;

my $t = test_instance;

use DateTime;
use utf8;
use Business::BR::CPF qw/random_cpf/;

my $schema2 = $t->app->schema2;

&test_cli_seg();

&test_faq();

done_testing();

exit;

sub test_cli_seg {

    my ($session, $user_id) = get_user_session('24115775670');
    my $cliente    = get_schema2->resultset('Cliente')->find($user_id);
    my $random_cpf = random_cpf();
    my ($session2, $user_id2) = get_user_session($random_cpf);
    my $cliente2 = get_schema2->resultset('Cliente')->find($user_id2);
    on_scope_exit { user_cleanup(user_id => $user_id2); };

    my $segment_rs = $schema2->resultset('AdminClientesSegment')->search(
        {
            is_test => '1',
        }
    );

    $segment_rs->delete;
    my $q = $segment_rs->create(
        {
            label   => 'test1',
            is_test => 1,
            cond    => to_json({'me.id' => $user_id}),
            attr    => to_json({}),
        }
    );

    my $q2 = $segment_rs->create(
        {
            label   => 'test1',
            is_test => 1,
            cond    => to_json({'me.cpf_hash' => [$cliente->cpf_hash, $cliente2->cpf_hash]}),
            attr    => to_json({}),
        }
    );

    is $q->last_run_at, undef, 'run is null';
    my $admin_email = 'tests.automatic@example.com';
    my $password    = 'k8Mw9)wj3H';

    # ID do role de test
    my $role_id = 7;
    my $admin   = $schema2->resultset('DirectusUser')->search(
        {
            status => 'active',
            email  => $admin_email
        }
    )->next;
    $ENV{ADMIN_ALLOWED_ROLE_IDS} = $role_id;
    $t->post_ok(
        '/admin/login',
        form => {
            email => $admin_email,
            senha => $password,
        },
    )->status_is(200)->json_is('/ok', '1', 'login was ok');

    $t->get_ok(
        '/admin/users',
        form => {segment_id => $q->id}
    )->status_is(200, 'filtro de segmento');

    ok $q->discard_changes->last_run_at, 'run is not null';
    is $q->last_count, 1, 'one row found';

    db_transaction2 {

        $cliente->notification_logs->delete;

        # se der errado, n pode afetar prod!

        $t->post_ok(
            '/admin/add-notification',
            form => {
                segment_id      => $q->id,
                message_title   => 'hey',
                message_content => 'kids',
            }
        )->status_is(200)->json_has('/notification_message_id', 'defined notification_message_id');

        ok my $msg = $cliente->notification_logs->next, 'notification_logs defined';

        is $msg->notification_message_id, last_tx_json->{notification_message_id},
          'notification_message_id matches';
        $cliente->notification_logs->delete;

        $t->post_ok(
            '/admin/add-notification',
            form => {
                cliente_id      => $cliente->id,
                message_title   => 'hey',
                message_content => 'kids',
            }
        )->status_is(200)->json_has('/notification_message_id', 'defined notification_message_id');

        ok $msg = $cliente->notification_logs->next, 'notification_logs defined';
        is $msg->notification_message_id, last_tx_json->{notification_message_id},
          'notification_message_id matches';

        $t->post_ok(
            '/admin/add-notification',
            form => {
                message_title   => 'hey',
                message_content => 'kids',
            }
        )->status_is(400)->json_is('/error', 'form_error');


        $t->post_ok(
            '/admin/add-notification',
            form => {
                segment_id      => $q2->id,
                message_title   => 'a',
                message_content => 'boo',
            }
        )->status_is(200)->json_has('/notification_message_id', 'defined notification_message_id');

        is get_schema2->resultset('NotificationLog')
          ->search({notification_message_id => last_tx_json->{notification_message_id}})->count, 2, '2 rows';
    };

    $segment_rs->delete;
}

sub test_faq {

    my $cats = $schema2->resultset('FaqTelaSobreCategoria')->search(
        {
            is_test => '1',
        }
    );
    $cats->search_related('faq_tela_sobres')->delete;
    $cats->delete;
    my $c2 = $cats->create(
        {
            title  => 'Cat2',
            sort   => 2,
            status => 'published',
        }
    );
    my $c1 = $cats->create(
        {
            title  => 'Cat1',
            sort   => 1,
            status => 'published',
        }
    );

    $c1->faq_tela_sobres->create(
        {
            title        => 'c1.a',
            content_html => 'content a',
            sort         => 2,
            status       => 'published',
        }
    );

    $c1->faq_tela_sobres->create(
        {
            title        => 'c1.b',
            content_html => 'content b',
            sort         => 3,
            status       => 'published',
        }
    );

    $c2->faq_tela_sobres->create(
        {
            title        => 'c2.a',
            content_html => 'content a 2',
            sort         => 1,
            status       => 'published',
        }
    );

    $t->get_ok(
        '/web/termos-de-uso',
    )->status_is(200, 'puxando termos_de_uso');

    $t->get_ok(
        '/web/politica-privacidade',
    )->status_is(200, 'puxando politica-privacidade');

    $t->get_ok(
        '/web/faq',
      )->status_is(200, 'puxando faq')    #
      ->element_count_is('a.faq-sobre-link', '3', '3 links faq')                    #
      ->text_like('div[id=heading' . $c1->id . '] h5', qr/Cat1/, 'cat1 present')    #
      ->text_like('div[id=heading' . $c2->id . '] h5', qr/Cat2/, 'cat2 present');

    $cats->search_related('faq_tela_sobres')->delete;
    $cats->delete;
}