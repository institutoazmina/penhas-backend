use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Penhas::Test;

my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;

my $cliente = get_schema2->resultset('Cliente')->find(42335);
my $session = $cliente->clientes_active_sessions->next;
$session = $t->app->encode_jwt(
    {
        ses => $session->id,
        typ => 'usr'
    }
);

my $x = $t->get_ok(
    '/me/audios',
    {'x-api-key' => $session}
)->status_is(200)->tx->res->json;


foreach (@{$x->{rows}}) {
    $t->get_ok(
        '/me/audios/' . $_->{data}{event_id} . '/download',
        {'x-api-key' => $session},
        form => {audio_sequences => 'all'}
    )->status_is(200)->tx->result->save_to('/tmp/xx/' . $_->{data}{last_cliente_created_at} . '.mp3');

}


done_testing();

exit;
