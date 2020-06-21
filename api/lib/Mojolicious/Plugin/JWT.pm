package Mojolicious::Plugin::JWT;
use Mojo::Base 'Mojolicious::Plugin';

use Crypt::JWT qw(decode_jwt encode_jwt);

use Crypt::OpenSSL::RSA;

sub register {
    my ($self, $app, $args) = @_;

    my $secret = $args->{secret} || die 'JWT: pvt must be defined';

    my $encode_sub = sub {
        my $c                 = shift;
        my $data              = shift;
        my $do_not_touch_data = shift;

        if (!$do_not_touch_data) {
            $data->{nbf} = time() - 1;
            $data->{iss} = 'P';
        }

        my $jws_token = encode_jwt(
            payload => $data,
            alg     => $data->{iss} && $data->{iss} eq 'P' ? 'HS384' : 'HS256',
            key     => $secret
        );
        return $jws_token;
    };

    $app->helper(encode_jwt => $encode_sub);

    $app->helper(
        decode_jwt => sub {
            my $c         = shift;
            my $jws_token = shift;
            return decode_jwt(
                token        => $jws_token,
                key          => $secret,
                verify_exp   => undef,
                verify_nbf   => undef,
                accepted_alg => ['HS256', 'HS384']
            );
        }
    );

}

1;
