use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../t/lib";
use DateTime;
use Penhas::Test;
use Penhas::Minion::Tasks::SendSMS;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;
use DateTime;

$ENV{GEOCODE_USE_HERE_API} = 1;
if ($ENV{GEOCODE_HERE_APP_ID}) {
    my $res = $t->app->geo_code_cached('04002-003 Brasil');
    is($res, '-23.57276,-46.65084', 'ok');

    my $res2 = $t->app->reverse_geo_code_cached($res);
    like $res2, qr/Vila Mariana/i, 'fair ok';
}

done_testing();

exit;
