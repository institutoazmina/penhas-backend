use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;
my $t = test_instance;

my $session = get_user_session('30085070343');

$ENV{FILTER_QUESTIONNAIRE_IDS} = '4,5';

    my $cadastro = $t->get_ok(
        '/me',
        {'x-api-key' => $session}
    )->status_is(200)->tx->res->json;

use DDP;
p $session;

done_testing();

exit;
