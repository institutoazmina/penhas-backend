package Mojolicious::Plugin::Detach;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;

    $app->helper(
        detach => sub {
            $app->log->warn("Mojolicious::Plugin::Detach::detach(): DEPRECATED!");
            return undef;
        }
    );
}

1;
 