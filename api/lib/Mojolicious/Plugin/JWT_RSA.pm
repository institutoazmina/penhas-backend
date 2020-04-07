package Mojolicious::Plugin::JWT_RSA;
use Mojo::Base 'Mojolicious::Plugin';

use Crypt::JWT qw(decode_jwt encode_jwt);

use Crypt::OpenSSL::RSA;

sub register {
    my ($self, $app, $args) = @_;

    my $rsa_pvt = Crypt::OpenSSL::RSA->new_private_key($args->{pvt} || die 'JWT: pvt must be defined');
    my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($args->{pub}  || die 'JWT: pub must be defined');

    my $encode_sub = sub {
        my $c                 = shift;
        my $data              = shift;
        my $do_not_touch_data = shift;

        if (!$do_not_touch_data) {
            $data->{nbf} = time() - 1;
            $data->{iss} = 'TB';
        }

        #die 'missing exp' unless exists $data->{exp};

        my $jws_token = encode_jwt(payload => $data, alg => 'RS256', key => $rsa_pvt);
        return $jws_token;
    };

    # little hack
    *main::jwt_encode = $encode_sub;

    $app->helper(encode_jwt => $encode_sub);

    $app->helper(
        decode_jwt => sub {
            my $c         = shift;
            my $jws_token = shift;
            return decode_jwt(
                token        => $jws_token,
                key          => $rsa_pub,
                verify_exp   => undef,
                verify_nbf   => undef,
                accepted_alg => 'RS256'
            );
        }
    );

    $app->helper(
        decode_jwt_shared => sub {
            my $c            = shift;
            my $jws_token    = shift;
            my $shared_token = shift;

            return decode_jwt(
                token        => $jws_token,
                key          => $shared_token,
                verify_exp   => undef,
                verify_nbf   => 0,
                accepted_alg => 'HS256'
            );
        }
    );

    $app->helper(
        load_user_from_jwt => sub {
            my $c = shift;

            my $jwt_key = $c->req->param('api_key') || $c->req->headers->header('x-api-key');

            # Authenticated
            if ($jwt_key) {
                my $claims = eval { $c->decode_jwt($jwt_key) };

                if ($@) {
                    return undef;
                }

                $c->stash(claims => $claims);

                # Permitindo jwt short para compatibilidade de testes
                if (defined $claims && ref $claims eq 'HASH' && defined $claims->{sub} && $claims->{sub} eq 'login') {
                    return 1;
                }

                # Fez o parser, e o tipo da chave é de usuario
                elsif (defined $claims && ref $claims eq 'HASH' && $claims->{typ} eq 'usr') {
                    $c->stash(
                        user_id    => $claims->{uid},
                        user_roles => $claims->{user_roles},
                        user_rs    => $c->schema->resultset('User')->search_rs({'me.id' => $claims->{uid}}),
                    );

                    # Can continue
                    return 1;
                }
                elsif (defined $claims && ref $claims eq 'HASH' && $claims->{typ} eq 'rbt') {

                    $c->stash(
                        team_robot_id => $claims->{uid},
                        team_robot_rs => $c->schema->resultset('TeamRobot')->search_rs(
                            {'me.id' => $claims->{uid}, 'team_robot_sessions.api_key' => $claims->{jti},},
                            {join    => 'team_robot_sessions'}
                        ),
                        merge_config => $claims->{merge_config},
                    );

                    # Can continue
                    return 1;
                }
                elsif (defined $claims && ref $claims eq 'HASH') {

                    # Can continue
                    return 1;
                }
                else {
                    $c->render(json => {error => "Not Authenticated"}, status => 401);

                    return $c->detach();

                }
            }

            return;
        }
    );
}

1;
