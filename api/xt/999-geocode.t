use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../t/lib";
use DateTime;
use Penhas::Test;
use Penhas::Minion::Tasks::SendSMS;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;
use DateTime;

$ENV{GEOCODE_USE_HERE_API} = 0;
if ($ENV{GOOGLE_GEOCODE_API}) {
    my $res = $t->app->geo_code('04002003 Brasil');
    is($res, '-23.5727455,-46.6507714', 'ok');

    # o google volta o endereco de outra rua kk, entao tive q pegar outro lat/lng
    my $res2 = $t->app->reverse_geo_code('-23.572445, -46.650549');
    like $res2, qr/maria fig/i, 'name ok';
}

$ENV{GEOCODE_USE_HERE_API} = 1;
if ($ENV{GEOCODE_HERE_APP_ID}) {
    my $res = $t->app->geo_code('04002003 Brasil');
    is($res, '-23.57276,-46.65084', 'ok');

    my $res2 = $t->app->reverse_geo_code($res);
    like $res2, qr/Vila Mariana/i, 'name ok';
}

done_testing();

exit;
