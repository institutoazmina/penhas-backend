package Penhas::Controller::Admin::Badges;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Penhas::Utils;
use Penhas::Logger;
use Mojo::Util qw/trim/;

sub show_assign_form {
    my $c = shift;
    $c->use_redis_flash();
    $c->stash(template => 'admin/assign_badges');

    # Fetch badges for the dropdown
    my @badges = $c->schema2->resultset('Badge')->search(
        {
            id => {'>' => 0},    # Exclude test badges
        },
        {
            order_by     => 'name',
            columns      => [qw/id name code/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all();

    $c->stash(badges => \@badges);
    return $c->render(html => {});
}

sub process_assign_list {
    my $c = shift;
    $c->use_redis_flash();

    $c->stash(template => 'admin/success_message');

    my $valid;

    my $form_key;

    # If this is a GET request with a form_key parameter, try to load the data
    if ($c->req->method eq 'GET' && $c->param('form_key')) {
        $form_key = $c->param('form_key');
        my $form_data = $c->get_form_data($form_key);

        if ($form_data) {

            $valid->{identifiers} = $form_data->{identifiers};
            $valid->{badge_id}    = $form_data->{badge_id};

        }
        else {
            # If no cached data, redirect to the input form
            return $c->redirect_to('/admin/badges');
        }
    }
    else {

        $valid = $c->validate_request_params(
            identifiers => {required => 1, type => 'Str', max_length => 50000},
            badge_id    => {required => 1, type => 'Int'},
        );

        # Store the form data in Redis with the custom method
        $form_key = $c->store_form_data(
            {
                identifiers => $valid->{identifiers},
                badge_id    => $valid->{badge_id}
            }
        );

    }


    my $badge = $c->schema2->resultset('Badge')->find($valid->{badge_id})
      or $c->reply_invalid_param('Badge não encontrado', 'form_error', 'badge_id', 'not_found');

    # --- Parse Identifiers ---
    my (@emails, @ids, @inputs);
    my %input_map;    # Keep track of original input for each found user
  IDENTIFIER: foreach my $line (split /[\n\r, ]+/, $valid->{identifiers}) {
        my $identifier = trim($line);
        next IDENTIFIER unless length $identifier;
        push @inputs, $identifier;

        if ($identifier =~ /^\d+$/) {
            push @ids, $identifier;
            $input_map{$identifier} = $identifier;
        }
        elsif ($identifier =~ /\@/) {    # Basic email check
            push @emails, lc $identifier;
            $input_map{lc $identifier} = $identifier;
        }
        else {
            # Handle invalid lines if necessary, or just ignore
            $c->app->log->debug("Ignoring invalid identifier line: $identifier");
        }
    }

    # --- Find Users ---
    my %found_users_by_id;
    if (@emails) {
        my @users = $c->schema2->resultset('Cliente')->search(
            {email => {-in => \@emails}},
            {
                columns      => [qw/id email nome_completo apelido/],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }    # Add columns as needed
        )->all;
        foreach my $user (@users) {
            $found_users_by_id{$user->{id}} = {%$user, original_input => $input_map{$user->{email}}};
        }
    }
    if (@ids) {
        my @users = $c->schema2->resultset('Cliente')->search(
            {id => {-in => \@ids}},
            {
                columns      => [qw/id email nome_completo apelido/],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }    # Add columns as needed
        )->all;
        foreach my $user (@users) {

            # Avoid overwriting if found by email earlier, maybe merge? For now, prioritize ID match.
            $found_users_by_id{$user->{id}} = {%$user, original_input => $input_map{$user->{id}}};
        }
    }

    # --- Check Current Badge Status ---
    my %has_active_badge_by_id;
    my %has_pending_invite_by_id;    # Track pending invites for the target badge
    if (keys %found_users_by_id) {

        # Active ClienteTag
        my @active_tags = $c->schema2->resultset('ClienteTag')->search(
            {
                cliente_id  => {-in => [keys %found_users_by_id]},
                badge_id    => $badge->id,
                valid_until => {'>' => \'now()'}
            },
            {columns => ['cliente_id']}
        )->all;
        $has_active_badge_by_id{$_->cliente_id} = 1 for @active_tags;

        # Pending BadgeInvite (only relevant for "circulo-penhas")
        if ($badge->code eq 'circulo-penhas') {
            my @pending_invites = $c->schema2->resultset('BadgeInvite')->search(
                {
                    cliente_id => {-in => [keys %found_users_by_id]},
                    badge_id   => $badge->id,
                    accepted   => 'false',
                    deleted    => 'false',
                },
                {columns => ['cliente_id']}
            )->all;
            $has_pending_invite_by_id{$_->cliente_id} = 1 for @pending_invites;
        }
    }

    # --- Build Confirmation List ---
    my @confirmation_list;
    my %processed_inputs;
    foreach my $input (@inputs) {
        my $found_user_data;

        # Find which user corresponds to this input
        foreach my $user_id (keys %found_users_by_id) {
            if ($found_users_by_id{$user_id}{original_input} eq $input) {
                $found_user_data = $found_users_by_id{$user_id};
                last;
            }
        }

        # Avoid duplicate entries if same user found via email and ID
        if ($found_user_data && $processed_inputs{$found_user_data->{id}}++) {
            $c->app->log->debug("Skipping duplicate user ID: " . $found_user_data->{id});
            next;
        }


        if ($found_user_data) {
            my $user_id        = $found_user_data->{id};
            my $has_badge      = $has_active_badge_by_id{$user_id};
            my $has_pending    = $has_pending_invite_by_id{$user_id};
            my $current_status = $has_badge ? 'active' : $has_pending ? 'pending_invite' : 'inactive';

# Default action: If they don't have it (active or pending), propose adding. If they have it, propose keeping. Admin can override.
            my $proposed_action = ($has_badge || $has_pending) ? 'keep' : 'add';

            push @confirmation_list, {
                input           => $input,
                user            => $found_user_data,
                cliente_id      => $user_id,
                current_status  => $current_status,
                proposed_action => $proposed_action,
            };
        }
        else {
            push @confirmation_list, {
                input           => $input,
                user            => undef,
                cliente_id      => undef,
                current_status  => 'not_found',
                proposed_action => 'keep',        # Cannot add/remove for non-existent user
            };
        }
    }

    # Pass the form_key to the template
    $c->stash(
        template          => 'admin/confirm_assign_badges',
        confirmation_list => \@confirmation_list,
        badge             => $badge,
        form_key          => $form_key
    );
    return $c->render(html => {});
}


sub confirm_assign_changes {
    my $c = shift;
    $c->use_redis_flash();

    use DDP;
    p $c->stash('temp_identifiers');
    my $form_key  = $c->param('form_key');
    my $form_data = $form_key ? $c->get_form_data($form_key) : undef;

    # If this is a GET request with no parameters, redirect to assign
    if ($c->req->method eq 'GET' && !$c->param('badge_id')) {
        return $c->redirect_to('/admin/badges');
    }

    $c->flash_to_redis(
        {
            temp_identifiers => $c->stash('temp_identifiers'),
            temp_badge_id    => $c->stash('temp_badge_id'),
        }
    );

    $c->stash(template => 'admin/badge_success');

    # Retrieve array parameters
    my $cliente_ids = $c->req->every_param('cliente_id');
    my $actions     = $c->req->every_param('action');

    log_info("Actions: ",     to_json($actions));
    log_info("Cliente IDs: ", to_json($cliente_ids));
    my $badge_id = $c->req->param('badge_id');

    # Ensure they are arrays for consistent processing
    $cliente_ids = [$cliente_ids] if $cliente_ids && ref $cliente_ids ne 'ARRAY';
    $actions     = [$actions]     if $actions     && ref $actions ne 'ARRAY';

    # Basic validation
    $c->reply_invalid_param('Dados de confirmação ausentes ou malformados.')
      unless $badge_id && $cliente_ids && $actions && @$cliente_ids == @$actions;

    my $badge = $c->schema2->resultset('Badge')->find($badge_id)
      or $c->reply_invalid_param('Badge não encontrado', 'form_error', 'badge_id', 'not_found');

    use DDP;
    p $badge;
    my $admin_user_id = $c->stash('admin_user')->id;

    my ($added_direct, $removed, $emailed, $errors, $skipped_notfound, $kept) = (0, 0, 0, 0, 0, 0);
    my $error_details = '';

    # Process changes within a transaction
    eval {
        $c->schema2->txn_do(
            sub {
                for my $i (0 .. $#$cliente_ids) {
                    my $cliente_id = $cliente_ids->[$i];
                    my $action     = $actions->[$i];

                    log_info("Processing user ID: $cliente_id, action: $action");

                    # Skip invalid/keep actions
                    unless ($cliente_id =~ /^\d+$/ && $action =~ /^(add|remove)$/) {
                        $kept++;
                        log_info("Skipping invalid action for user ID: $cliente_id");
                        next;
                    }

                    my $user_obj = $c->schema2->resultset('Cliente')->find($cliente_id);
                    unless ($user_obj) {
                        $c->app->log->warn("User ID $cliente_id not found during confirmation - skipping.");
                        $skipped_notfound++;
                        log_info("Skipping user ID $cliente_id, not found in database.");
                        next;
                    }

                    if ($action eq 'add') {
                        my $status = $c->schedule_add_badge(
                            user_obj      => $user_obj,
                            badge_obj     => $badge,
                            admin_user_id => $admin_user_id
                        );
                        if ($status eq 'email_sent') {
                            log_info("Badge invite email sent to user $cliente_id.");
                            $emailed++;
                        }
                        elsif ($status eq 'added_directly') {
                            log_info("Badge added directly to user $cliente_id.");
                            $added_direct++;
                        }
                        elsif ($status eq 'already_active' || $status eq 'invite_pending') {
                            $c->app->log->debug("Skipped adding badge for user $cliente_id, status: $status");

                            log_info("Badge already active or invite pending for user $cliente_id.");

                            # Optionally count these as 'kept' or a separate category
                            $kept++;
                        }
                        else {
                            # Handle unexpected status or error from helper
                            $errors++;
                            $error_details .= "Erro ao adicionar badge para user $cliente_id.\n";
                            log_error("Error adding badge for user $cliente_id, status: $status");
                            $c->app->log->error("Error adding badge for user $cliente_id, status: $status");

                            # NOTE: txn_do will likely rollback on die, so errors need careful handling
                            # For now, we just log and count.
                        }
                    }
                    elsif ($action eq 'remove') {
                        my $status = $c->schedule_remove_badge(
                            user_obj      => $user_obj,
                            badge_obj     => $badge,
                            admin_user_id => $admin_user_id
                        );
                        if ($status eq 'removed') {
                            log_info("Badge removed from user $cliente_id.");
                            $removed++;
                        }
                        elsif ($status eq 'no_action_needed') {
                            log_info("No action needed for user $cliente_id.");
                            $c->app->log->debug("Skipped removing badge for user $cliente_id, status: $status");
                            $kept++;
                        }
                        else {
                            $errors++;
                            $error_details .= "Erro ao remover badge para user $cliente_id.\n";
                            $c->app->log->error("Error removing badge for user $cliente_id, status: $status");
                            log_error("Error removing badge for user $cliente_id, status: $status");
                        }
                    }
                }    # end for loop

                # If severe errors occurred within the loop that caused a die,
                # the transaction might roll back. If we just counted errors, it commits.
                if ($errors > 0) {

                    log_error("Errors occurred during badge assignment: $error_details");
                    # Decide if errors should prevent commit. For now, let's commit successes.
                    $c->app->log->warn("Finished badge assignment with $errors errors.");
                }

            }
        );    # end txn_do
    };    # end eval
    if (my $err = $@) {
        $c->app->log->error("FATAL error during badge assignment transaction: $err");

        # Use flash for the error message only
        $c->flash_to_redis({message => "Erro fatal durante o processamento: $err"});

        # Redirect back to process_assign_list with the form_key
        return $c->redirect_to("/admin/badges/assign?form_key=$form_key");
    }


    # --- Prepare Summary Message ---
    my @summary_parts;
    push @summary_parts, "$added_direct adicionados"                  if $added_direct;
    push @summary_parts, "$removed removidos"                         if $removed;
    push @summary_parts, "$emailed convites enviados"                 if $emailed;
    push @summary_parts, "$kept mantidos/ignorados"                   if $kept;
    push @summary_parts, "$skipped_notfound usuários não encontrados" if $skipped_notfound;
    push @summary_parts, "$errors erros"                              if $errors;

    my $summary
      = @summary_parts ? "Processamento concluído: " . join(', ', @summary_parts) . "." : "Nenhuma ação realizada.";
    $summary .= "\nDetalhes do erro:\n" . $error_details if $errors;


    $c->flash_to_redis({($errors ? 'message' : 'success_message') => $summary});

    return $c->redirect_to('/admin/badges/success');
}

sub show_success {
    my $c = shift;
    $c->use_redis_flash();
    $c->stash(template => 'admin/badge_success');
    return $c->render(html => {});
}

1;
