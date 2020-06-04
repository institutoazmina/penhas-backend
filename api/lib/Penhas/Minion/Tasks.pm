package Penhas::Tasks;
use Mojo::Base -role;

use Penhas::SchemaConnected;

requires qw(do);

has schema => sub { get_schema() };

sub register {
    my $app = shift;


}

1;
