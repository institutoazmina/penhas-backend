package Penhas;
use Mojo::Base 'Mojolicious';

use Penhas::Config;
use Penhas::Helpers;
use Penhas::Routes;
use Penhas::Logger;
use Penhas::Utils;
use Penhas::SchemaConnected;
use Penhas::Authentication;

# carregar controllers usados usados
use Penhas::Controller::Me;
use Penhas::Controller::Me_Tweets;

sub startup {
    my $self = shift;

    # Config.
    Penhas::Config::setup($self);

    # Logger.
    undef $Penhas::Logger::instance;
    get_logger();
    $self->plugin('Log::Any' => {logger => 'Log::Log4perl'});

    # Helpers
    Penhas::Helpers::setup($self);

    # RSA keys.
    my $schema = $self->schema;
    my $secret = $schema->get_jwt_key;

    # usado pra assianr os cookies # https://docs.mojolicious.org/Mojolicious#secrets
    $self->secrets([$secret . '4COOKIES']);

    # Não precisa manter conexao no processo manager
    $self->schema->storage->dbh->disconnect if not $ENV{HARNESS_ACTIVE};

    # Plugins.
    $self->plugin('JWT', secret => $secret);

    $self->plugin('ParamLogger', filter => [qw(password senha senha_atual message)]);


    # servir a /public (templates de email e arquivos static)
    $self->plugin('RenderFile');

    $self->plugin('StaticCache' => {even_in_dev => 1, max_age => 31536000});

    # Minion (job manager)
    $self->plugin('Penhas::Minion');

    # Subprocess (do small background jobs without locking worker)
    $self->plugin('Subprocess');

    # Helpers.
    $self->controller_class('Penhas::Controller');

    # Routes.
    Penhas::Routes::register($self->routes);

    # minion admin
    # Secure access to the admin ui with Basic authentication
    my $under = $self->routes->under(
        '/minion' => sub {
            my $c = shift;
            return 1
              if $c->req->url->to_abs->userinfo eq 'admin:' . ($ENV{MINION_ADMIN_PASSWORD} || $c->reply_forbidden());
            $c->res->headers->www_authenticate('Basic');
            $c->render(text => 'Authentication required!', status => 401);
            return undef;
        }
    );
    $self->plugin('Minion::Admin' => {route => $under});

    $self->hook(
        around_dispatch => sub {
            my ($next, $c) = @_;
            Log::Log4perl::NDC->remove;

            $next->();
        }
    );

    # Security headers - adicionados em todas as respostas HTTP.
    # Ref: OWASP Secure Headers Project
    # Ticket: security/add-response-security-headers
    $self->hook(
        after_dispatch => sub {
            my $c       = shift;
            my $headers = $c->res->headers;

            $headers->header('X-Frame-Options'       => 'DENY');
            $headers->header('X-Content-Type-Options' => 'nosniff');
            $headers->header('X-XSS-Protection'       => '0');
            $headers->header('Content-Security-Policy' => "default-src 'self'; frame-ancestors 'none'");
            $headers->header('Referrer-Policy'         => 'strict-origin-when-cross-origin');
            $headers->header('Permissions-Policy'      => 'geolocation=(), camera=(), microphone=()');

            # HSTS apenas quando a conexão é (ou foi proxied como) HTTPS
            my $proto = $c->req->headers->header('X-Forwarded-Proto') || '';
            if ($c->req->is_secure || $proto eq 'https') {
                $headers->header('Strict-Transport-Security' => 'max-age=31536000; includeSubDomains');
            }

            # Cache-Control para respostas API - não sobrescreve valores já definidos por controllers
            if (!$headers->cache_control) {
                $headers->cache_control('no-store');
            }
        }
    );

}

1;
