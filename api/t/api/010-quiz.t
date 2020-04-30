use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;
my $t = test_instance;

my ($session, $user_id) = get_user_session('30085070343');

$ENV{FILTER_QUESTIONNAIRE_IDS} = '4,5';

my $quiz_sessions = app->directus->search(
    table => 'clientes_quiz_session',
    form  => {
        'filter[cliente_id][eq]' => $user_id,
    }
);

foreach ($quiz_sessions->{data}->@*) {
    app->directus->delete(
        table => 'clientes_quiz_session',
        id    => $_->{id}
    );
}

my $cadastro = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->tx->res->json;

is trace_popall(), 'clientes_quiz_session:created', 'clientes_quiz_session was created';

my $cadastro = $t->get_ok(
    '/me',
    {'x-api-key' => $session}
)->status_is(200)->tx->res->json;
is trace_popall(), 'clientes_quiz_session:loaded', 'clientes_quiz_session was just loaded';

use DDP;
p $session;

done_testing();

exit;
