package Penhas;
use Mojo::Base 'Mojolicious';

use Penhas::Config;
use Penhas::Helpers;
use Penhas::Routes;
use Penhas::Logger;
use Penhas::Utils;
use Penhas::SchemaConnected;
use Penhas::Authentication;

sub startup {
    my $self = shift;

    # Config.
    Penhas::Config::setup($self);

    # Logger.
    get_logger();
    $self->plugin('Log::Any' => {logger => 'Log::Log4perl'});

    # Helpers
    Penhas::Helpers::setup($self);

    # RSA keys.
    my $schema = $self->schema;
    my (%rsa) = $schema->get_rsa_keys;

    # Não precisa manter conexao no processo manager
    $self->schema->storage->dbh->disconnect if not $ENV{HARNESS_ACTIVE};

    # Plugins.
    $self->plugin('JWT_RSA', pub => delete $rsa{pub}, pvt => delete $rsa{pvt});

    # Helpers.
    $self->controller_class('Penhas::Controller');

    # Routes.
    Penhas::Routes::register($self->routes);


}

1;
