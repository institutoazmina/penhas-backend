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
            $data->{iss} = 'P';
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

}

1;
