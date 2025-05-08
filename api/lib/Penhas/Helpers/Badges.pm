package Penhas::Helpers::Badges;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON qw(to_json encode_json);
use Penhas::Logger;
use Penhas::Utils;
use DateTime;
use Mojo::URL;


sub setup {
    my $self = shift;

    $self->helper('cliente_add_badge'           => sub { &cliente_add_badge(@_) });
    $self->helper('schedule_add_badge'          => sub { &schedule_add_badge(@_) });
    $self->helper('schedule_remove_badge'       => sub { &schedule_remove_badge(@_) });
    $self->helper('confirm_badge_add'           => sub { &confirm_badge_add(@_) });
    $self->helper('validate_badge_invite_token' => sub { &validate_badge_invite_token(@_) });
}

sub cliente_add_badge {
    my ($c, %opts) = @_;

    my $badge_id = $opts{badge_id} or confess 'missing badge_id';
    my $user     = $opts{user_obj} or confess 'missing user_obj';
    return {} unless $user->is_female();

    my $badge = $c->schema2->resultset('Badge')->find($badge_id);
    die {message => 'Badge não encontrada', error => 'badge_not_found'} unless $badge;

    my $badge_cliente = $c->schema2->resultset('ClienteTag')->search(
        {
            badge_id    => $badge_id,
            cliente_id  => $user->id,
            valid_until => {'>' => \'now()'}
        }
    )->next;

    if (!$badge_cliente) {
        $c->schema2->resultset('ClienteTag')->search(
            {
                badge_id    => $badge_id,
                cliente_id  => $user->id,
                valid_until => {'>' => \'now()'},
            }
        )->update(
            {
                valid_until => \'now()',
            }
        );

        # Set validity to 1 year from now instead of infinity
        my $valid_until = DateTime->now->add(years => 1)->strftime('%Y-%m-%d %H:%M:%S');

        $c->schema2->resultset('ClienteTag')->create(
            {
                badge_id    => $badge_id,
                cliente_id  => $user->id,
                created_on  => \'now()',
                valid_until => $valid_until
            }
        );
        log_info("BadgeTag created for cliente_id=" . $user->id . ", badge_id=" . $badge_id);
        return 1;
    }
    else {
        log_info("BadgeTag already active for cliente_id=" . $user->id . ", badge_id=" . $badge_id);
        return 1;
    }
}

sub schedule_add_badge {
    my ($c, %opts) = @_;

    my $user          = $opts{user_obj}      or confess 'missing user_obj';
    my $badge         = $opts{badge_obj}     or confess 'missing badge_obj';
    my $admin_user_id = $opts{admin_user_id} or confess 'missing admin_user_id';

    # 1. Check if user already has an active tag for this badge
    my $active_tag = $c->schema2->resultset('ClienteTag')->search(
        {
            cliente_id  => $user->id,
            badge_id    => $badge->id,
            valid_until => {'>' => \'now()'},
        }
    )->count;

    if ($active_tag) {
        log_info("Badge " . $badge->id . " already active for user " . $user->id);
        return 'already_active';
    }

    # 2. Special handling for 'circulo-penhas'
    if ($badge->code eq 'circulo-penhas') {
        my $pending_invite = $c->schema2->resultset('BadgeInvite')->search(
            {
                cliente_id => $user->id,
                badge_id   => $badge->id,
                accepted   => 'false',
                deleted    => 'false',
            }
        )->first;

        if ($pending_invite) {
            log_info("Pending invite already exists (ID: "
                  . $pending_invite->id
                  . ") for badge "
                  . $badge->id
                  . " and user "
                  . $user->id);

            # Optionally: Resend email? For now, just indicate it's pending.
            return 'invite_pending';
        }

        my $invite = $c->schema2->resultset('BadgeInvite')->create(
            {
                cliente_id    => $user->id,
                badge_id      => $badge->id,
                admin_user_id => $admin_user_id,
                created_on    => \'now()',
                modified_on   => \'now()',
            }
        );
        die "Failed to create BadgeInvite" unless $invite && $invite->id;
        log_info("Created BadgeInvite ID: " . $invite->id);
        use DDP;
        p $invite;

        my $expires_in_seconds = 400 * 24 * 60 * 60;
        my $token              = $c->encode_jwt(
            {
                iss => 'BdgInv',
                bid => $badge->id,
                uid => $user->id,
                inv => $invite->id,
                exp => time() + $expires_in_seconds,
            },
            1
        );

        my $accept_url = Mojo::URL->new('/badge/accept');
        $accept_url->query({token => $token});
        my $full_url = $c->req->url->to_abs->base . $accept_url;

        my $email_vars = {
            nome_completo => $user->nome_completo,
            accept_url    => $full_url,
            badge_name    => $badge->name,
        };
        my $email_db = $c->schema->resultset('EmaildbQueue')->create(
            {
                config_id => 1,
                template  => 'circulo_penhas_invite.html',
                to        => $user->email,
                subject   => 'Confirmação de inscrição - Voluntária PenhaS/Círculo PenhaS',
                variables => encode_json($email_vars),
            }
        );
        die 'Failed to enqueue email' unless $email_db && $email_db->id;
        log_info("Enqueued email for BadgeInvite ID: " . $invite->id . ", EmaildbQueue ID: " . $email_db->id);

        return 'email_sent';
    }
    else {
        my $added = $c->cliente_add_badge(user_obj => $user, badge_id => $badge->id);
        return $added ? 'added_directly' : 'add_failed';
    }
}

sub schedule_remove_badge {
    my ($c, %opts) = @_;

    my $user          = $opts{user_obj}      or confess 'missing user_obj';
    my $badge         = $opts{badge_obj}     or confess 'missing badge_obj';
    my $admin_user_id = $opts{admin_user_id} or confess 'missing admin_user_id';

    my $tag_updated    = 0;
    my $invite_updated = 0;

    my $updated_count = $c->schema2->resultset('ClienteTag')->search(
        {
            cliente_id  => $user->id,
            badge_id    => $badge->id,
            valid_until => {'>' => \'now()'}
        }
    )->update({valid_until => \'now()'});

    if ($updated_count > 0) {
        log_info("Deactivated active ClienteTag for user " . $user->id . ", badge " . $badge->id);
        $tag_updated = 1;
    }

    my $updated_invite_count = $c->schema2->resultset('BadgeInvite')->search(
        {
            cliente_id => $user->id,
            badge_id   => $badge->id,
            accepted   => 'false',
            deleted    => 'false',
        }
    )->update(
        {
            deleted     => 'true',
            deleted_on  => \'now()',
            modified_on => \'now()',
        }
    );

    if ($updated_invite_count > 0) {
        log_info("Deactivated pending BadgeInvite for user " . $user->id . ", badge " . $badge->id);
        $invite_updated = 1;
    }

    return ($tag_updated || $invite_updated) ? 'removed' : 'no_action_needed';
}

sub confirm_badge_add {
    my ($c, %opts) = @_;
    my $invite_id = $opts{invite_id} or confess 'missing invite_id';
    my $ip        = $opts{accepted_ip};
    my $ua        = $opts{accepted_user_agent};

    my $invite = $c->schema2->resultset('BadgeInvite')->find(
        $invite_id,
        {prefetch => ['cliente', 'badge']}
    );

    unless ($invite) {
        log_warn("Confirm badge add failed: Invite ID $invite_id not found.");
        return 0;
    }
    unless ($invite->cliente && $invite->badge) {
        log_error("Confirm badge add failed: Missing cliente or badge for Invite ID $invite_id.");
        return 0;
    }
    if ($invite->accepted) {
        log_info("Confirm badge add: Invite ID $invite_id already accepted.");
        return 1;
    }
    if ($invite->deleted) {
        log_warn("Confirm badge add failed: Invite ID $invite_id was deleted.");
        return 0;
    }

    my $added = $c->cliente_add_badge(user_obj => $invite->cliente, badge_id => $invite->badge_id);

    unless ($added) {
        log_error("Confirm badge add failed: cliente_add_badge returned false for invite ID " . $invite->id);
        return 0;
    }

    $invite->update(
        {
            accepted            => 'true',
            accepted_on         => \'now()',
            accepted_ip         => $ip,
            accepted_user_agent => substr($ua || '', 0, 1999),
            modified_on         => \'now()',
        }
    );

    log_info("Successfully confirmed and added badge for Invite ID " . $invite->id);
    return 1;
}

sub validate_badge_invite_token {
    my ($c, %opts) = @_;
    my $token_str = $opts{token} or confess 'Missing token for validation';

    my $payload;
    eval { $payload = $c->decode_jwt($token_str); };
    if ($@ || ref $payload ne 'HASH') {
        log_error("Badge invite JWT decode error: $@") if $@;
        return {status => 'invalid_token', message => 'O link utilizado é inválido.'};
    }

    unless (($payload->{iss} || '') eq 'BdgInv') {
        log_error("Badge invite JWT issuer mismatch: " . ($payload->{iss} // 'undef'));
        return {status => 'invalid_issuer', message => 'O link utilizado não é válido para esta ação.'};
    }

    my $invite_id  = $payload->{inv};
    my $cliente_id = $payload->{uid};
    my $badge_id   = $payload->{bid};
    my $expiry     = $payload->{exp};

    unless ($invite_id && $cliente_id && $badge_id && $expiry) {
        log_error("Badge invite JWT payload missing required fields: " . to_json($payload));
        return {status => 'invalid_payload', message => 'O link utilizado está incompleto.'};
    }

    if (time() > $expiry) {
        log_info("Badge invite JWT token expired for invite $invite_id");

        # Optionally mark the invite as expired in the DB here if desired
        my $expired_invite = $c->schema2->resultset('BadgeInvite')->find($invite_id);
        if ($expired_invite && !$expired_invite->accepted && !$expired_invite->deleted) {
            $expired_invite->update({deleted => 1, deleted_on => \'now()', modified_on => \'now()'});
            log_info("Marked expired BadgeInvite ID $invite_id as deleted.");
        }
        return {status => 'expired_token', message => 'Este link de convite expirou.'};
    }

    # Fetch the invite with related objects
    my $invite = $c->schema2->resultset('BadgeInvite')->find(
        $invite_id,
        {prefetch => ['cliente', 'badge']}
    );

    unless ($invite) {
        log_warn("Badge invite validation: Invite ID $invite_id not found in database.");
        return {status => 'invite_not_found', message => 'O convite associado a este link não foi encontrado.'};
    }

    # Verify consistency between token payload and database record
    unless ($invite->cliente_id == $cliente_id && $invite->badge_id == $badge_id) {
        log_error("Badge invite token/DB mismatch for invite ID $invite_id. Token UID: $cliente_id, DB UID: "
              . $invite->cliente_id
              . ". Token BID: $badge_id, DB BID: "
              . $invite->badge_id);
        return {status => 'token_mismatch', message => 'O link utilizado não corresponde aos dados do convite.'};
    }

    # Check invite status from DB
    if ($invite->deleted) {
        log_info("Badge invite validation: Invite ID $invite_id was already deleted.");
        return {status => 'invite_deleted', message => 'Este convite foi cancelado ou expirou.'};
    }

    if ($invite->accepted) {
        log_info("Badge invite validation: Invite ID $invite_id was already accepted.");

        # check if still valid
        my $still = $c->schema2->resultset('ClienteTag')->search(
            {
                cliente_id  => $invite->cliente_id,
                badge_id    => $invite->badge_id,
                valid_until => {'>' => \'now()'},
            }
        )->next;
        my $valid_until = $still ? $still->valid_until : undef;

        if (!$still) {
            log_info("Badge invite validation: Invite ID $invite_id is no longer valid.");
            return {
                status  => 'invite_expired',
                message => 'Este convite já foi aceito, mas já foi cancelado ou expirou.',
                user    => $invite->cliente,    # Return user for display purposes
                badge   => $invite->badge,      # Return badge for display purposes
            };
        }

        return {
            status  => 'invite_already_accepted',
            message => 'Este convite já foi aceito anteriormente.',
            user    => $invite->cliente,                              # Return user for display purposes
            badge   => $invite->badge,                                # Return badge for display purposes
        };
    }

    # All checks passed
    return {
        status => 'ok',
        invite => $invite,
        user   => $invite->cliente,
        badge  => $invite->badge,
    };
}


1;
