package Penhas::Controller::Admin::Session;
use Mojo::Base 'Penhas::Controller';
use utf8;

use DateTime;
use MooseX::Types::Email qw/EmailAddress/;

sub admin_login {
    my $c = shift;

    my $params = $c->validate_request_params(
        email => {max_length => 200, required => 1, type => EmailAddress},
        senha => {max_length => 200, required => 1, type => 'Str', min_length => 6},
    );
    my $email = lc($params->{email});
    my $senha = $params->{senha};

    # limite de requests por segundo no IP
    # no maximo 3 request por minuto
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(3, 60);

    # procura pelo email
    my $found_obj = $c->schema2->resultset('DirectusUser')->search(
        {email => $email, status => 'active'},
    )->next;

    if ($found_obj) {

        # confere a senha
        if ($found_obj->check_password($senha)) {

            my $role_id = $found_obj->role;

            if ((',' . ($ENV{ADMIN_ALLOWED_ROLE_IDS} || '') . ',') =~ qr/,$role_id,/) {
                goto SUCCESS;
            }

        }
    }

    # fluxo padrao é dar erro
    die {
        error   => 'wrongpassword',
        message => 'E-mail ou senha inválido, ou não você está sem permissão para logar.',
        field   => 'password',
        reason  => 'invalid'
    };

  SUCCESS:
    $c->session->{admin_user_id} = $found_obj->id;

    $c->render(
        json => {
            ok   => 1,
            name => $found_obj->first_name,
        },
        status => 200,
    );
}

sub admin_logout {
    my $c = shift;

    $c->session(expires => 1);

    $c->render(
        json => {
            ok => 1,
        },
        status => 200,
    );
}

sub admin_check_authorization {
    my $c = shift;

    $c->reply_forbidden() unless $c->session->{admin_user_id};

    my $admin = $c->schema2->resultset('DirectusUser')->search(
        {id => $c->session->{admin_user_id}, status => 'active'},
    )->next;
    $c->reply_forbidden() unless $admin;

    $c->log->info(sprintf 'Logged as %s', $admin->id . ' ' . $admin->first_name);

    $c->stash(
        looged_as_admin => 1,
        admin_user      => $admin,
    );

    return 1;
}

sub admin_dashboard {
    my $c = shift;

    $c->render(
        json => {
            ok => 1,
        },
        status => 200,
    );

}
1;
