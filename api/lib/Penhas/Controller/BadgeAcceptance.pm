package Penhas::Controller::BadgeAcceptance;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use DateTime;
use Penhas::Logger;
use Penhas::Utils;    # Assuming JWT secret is accessible or helpers handle it

sub apply_rps {
    my $c = shift;

    # Limit requests per second on the IP
    my $remote_ip = $c->remote_addr();

    # Truncate the IPV6 to only the prefix (18 chars)
    $c->stash(apply_rps_on => 'B' . substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(100, 3600);

    $c->stash(template => 'public/badge_accepted');

    return 1;
}

sub accept_invite {
    my $c = shift;

    # --- Determine Method and Get Token ---
    my $token;
    my $is_post = $c->req->method eq 'POST';

    if ($is_post) {
        $token = $c->req->param('token');
    }
    else {
        $token = $c->req->url->query->param('token');
    }

    unless ($token) {
        $c->app->log->warn("BadgeAcceptance: No token provided.");
        $c->stash(msg_status => 'error', message => 'Link de confirmação inválido ou ausente.');
        return $c->render(html => {});
    }

    # Use the existing validation service
    my $result = $c->validate_badge_invite_token(token => $token);

    # Handle validation errors using the structured response
    if ($result->{status} ne 'ok') {
        $c->app->log->info("BadgeAcceptance: Token validation failed: $result->{status}");
        $c->stash(
            msg_status => $result->{status},
            message    => $result->{message},

            # Pass any additional data from result if available
            user  => $result->{user},
            badge => $result->{badge},
        );
        return $c->render(html => {});
    }

    # We have a valid invite at this point
    my $invite = $result->{invite};

    # --- Handle GET Request (Show Confirmation) ---
    unless ($is_post) {
        $c->stash(
            msg_status => 'ok',
            user       => $result->{user},
            badge      => $result->{badge},
            token      => $token,             # Pass token back to the form
        );
        return $c->render(html => {});
    }

    # --- Handle POST Request (Process Confirmation) ---
    my $success = $c->confirm_badge_add(
        invite_id           => $invite->id,
        accepted_ip         => $c->remote_addr(),
        accepted_user_agent => $c->req->headers->user_agent,
    );

    if ($success) {
        $c->stash(
            msg_status => 'confirmed_success',
            user       => $result->{user},
            badge      => $result->{badge},
        );
        return $c->render(html => {});
    }
    else {
        # confirm_badge_add failed (logged internally by the helper)
        $c->stash(
            msg_status => 'confirmation_error',
            message => 'Ocorreu um erro ao tentar ativar o seu selo. Por favor, tente novamente ou contate o suporte.',
            user    => $result->{user},
            badge   => $result->{badge},
        );
        return $c->render(html => {});
    }
}

1;
