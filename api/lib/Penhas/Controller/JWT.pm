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
            $c->render(json => {error => 'expired_jwt', nessage => "Bad request - Invalid JWT"}, status => 400);
            $c->app->log->error("JWT Error: $@");
            return undef;
        }

        # Fez o parser, e o tipo da chave é de usuario
        if (defined $claims && ref $claims eq 'HASH' && $claims->{typ} eq 'usr') {

            # TODO usar o redis pra nao precisar ir toda hora no banco de dados
            my $item = $c->schema2->resultset('ClientesActiveSession')->search(
                {'me.id'      => $claims->{ses}},
                {
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                    columns => ['cliente_id']
                }
            )->next;
            if (!$item) {
                $c->render(
                    json => {error => 'jwt_logout', message => "Está sessão não está mais válida (Usuário saiu)"},
                    status => 403
                );
                return undef;
            }
            my $user_id = $item->{cliente_id};

            Log::Log4perl::NDC->remove;
            Log::Log4perl::NDC->push('user-id:' . $user_id);

            $c->stash(
                apply_rps_on   => 'D' . $user_id,
                user_id        => $user_id,
                jwt_session_id => $claims->{ses}
            );

            $c->res->headers->header('x-extra' => 'user-id:' . $user_id);

            # 120 requests over 60 seconds
            $c->apply_request_per_second_limit(120, 60);

            # Can continue
            return 1;
        }
    }

    die {status => 401, error => 'missing_jwt', message => "Not Authenticated"};
}

1;
