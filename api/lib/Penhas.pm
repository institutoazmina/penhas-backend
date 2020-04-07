package Penhas;
use Mojo::Base 'Mojolicious';

use Penhas::Config;
use Penhas::Routes;
use Penhas::Controller;
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

    # Helpers.
    $self->helper(schema => sub { state $schema = Penhas::SchemaConnected->get_schema(@_) });

    # Não precisa manter conexao no processo manager
    $self->schema->storage->dbh->disconnect if not $ENV{HARNESS_ACTIVE};

    # RSA keys.
    my $schema = $self->schema;
    my (%rsa) = $schema->get_rsa_keys;

    # Plugins.
    $self->plugin('Detach');
    $self->plugin('RenderFile');
    $self->plugin('JWT_RSA', pub => delete $rsa{pub}, pvt => delete $rsa{pvt});
    $self->plugin(
        'SimpleAuthentication',
        {
            validate_user => sub { Penhas::Authentication::validate_user(@_) }
        }
    );

    # Helpers.
    $self->controller_class('Penhas::Controller');
    $self->helper('reply.exception' => sub { Penhas::Controller::reply_exception(@_) });
    $self->helper('reply.not_found' => sub { Penhas::Controller::reply_not_found(@_) });
    $self->helper('user_not_found'  => sub { Penhas::Controller::reply_not_found(@_, type => 'user_not_found') });

    # Routes.
    Penhas::Routes::register($self->routes);


}

1;
