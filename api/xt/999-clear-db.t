use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../t/lib";
use DateTime;
use Penhas::Test;
use Penhas::Minion::Tasks::SendSMS;
my $t = test_instance;
use Business::BR::CPF qw/random_cpf/;
use DateTime;

my $schema2 = $t->app->schema2;

my $ids = [
    map { $_->id } $schema2->resultset('Cliente')->search(
        {
            email         => {'like' => '%@something.com'},
            nome_completo => {'!='   => 'Quiz User Name'},
        },

    )->all
];

user_cleanup(user_id => $ids) if @$ids > 0;
ok('1', 'ok');

done_testing();

exit;
