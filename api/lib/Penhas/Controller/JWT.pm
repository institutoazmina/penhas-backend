package Penhas::Controller::JWT;
use Mojo::Base 'Penhas::Controller';
use utf8;

use JSON;

sub check_user_jwt {
    my $c = shift;

    my $jwt_key = $c->req->param('api_key') || $c->req->headers->header('x-api-key');

    # Authenticated
    if ($jwt_key) {
        my $claims = eval { $c->decode_jwt($jwt_key) };
        if ($@) {
            $c->render(json => {error => "Bad request - Invalid JWT"}, status => 400);
            $c->app->log->error("JWT Error: $@");
            return undef;
        }

        # Fez o parser, e o tipo da chave é de usuario
        if (defined $claims && ref $claims eq 'HASH' && $claims->{typ} eq 'usr') {

            # TODO usar o redis pra nao precisar ir toda hora no banco de dados
            my $item = $c->directus->search_one(
                table => 'clientes_active_sessions',
                form  => {
                    'filter[id][eq]' => $claims->{ses},
                }
            );
            if (!$item) {
                $c->render(json => {error => "This session was logout"}, status => 403);
                return undef;
            }

            my $user_id = $item->{cliente_id};

            Log::Log4perl::NDC->remove;
            Log::Log4perl::NDC->push('user-id:' . $user_id);

            $c->stash(
                apply_rps_on      => 'D' . $user_id,
                user_id           => $user_id,
                mastodon_oauth_id => $claims->{_oi},
                jwt_session_id    => $claims->{ses}
            );

            $c->res->headers->header('x-extra' => 'user-id:' . $user_id);

            # 120 requests over 60 seconds
            $c->apply_request_per_second_limit(120, 60);

            # Can continue
            return 1;
        }
    }

    die {status => 401, error => "Not Authenticated"};
}

1;
