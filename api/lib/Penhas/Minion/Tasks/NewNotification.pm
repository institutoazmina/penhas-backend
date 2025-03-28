package Penhas::Minion::Tasks::NewNotification;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Digest::MD5 qw/md5_hex/;
use Penhas::Uploader;
use Mojo::DOM;
use warnings FATAL => 'all';

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(new_notification => \&new_notification);
}

sub new_notification {
    my ($job, $type, $opts) = @_;

    log_trace("minion:new_notification", $type);

    my $known_types = {
        new_comment => 'new_notification_comment',
        new_like    => 'new_notification_like',
        new_message => 'new_notification_chat',

        new_post_local_badge_holder       => 'new_notification_post_local_badge_holder',
        new_post_linked_city_badge_holder => 'new_notification_post_linked_city_badge_holder',
    };

    my $subname = $known_types->{$type} || die "notification type $type is not known";

    my (%ret) = __PACKAGE__->$subname($job, $type, $opts);

    # reseta o cache de quem recebeu notificação
    $job->app->user_notifications_clear_cache($_->{cliente_id}) for @{$ret{clientes} || []};

    return $job->finish(1);

}

sub new_notification_chat {
    my (undef, $job, $type, $opts) = @_;

    my $schema2 = $job->app->schema2;    # mysql
    my $logger  = $job->app->log;

    my $message = {
        is_test    => is_test()                 ? 1  : 0,
        title      => $opts->{subject_id} == -1 ? '' : 'enviou uma mensagem',
        content    => '',
        meta       => to_json({chat => 1}),
        subject_id => $opts->{subject_id},
        created_at => \'now()',
        icon       => 1,
    };

    my $preference_name = 'NOTIFY_CHAT_NEW_MESSAGES';
    my @clientes        = $job->app->rs_user_by_preference($preference_name, '1')->search(
        {
            cliente_id => $opts->{cliente_id},
        }
    )->all;

    log_trace($preference_name, scalar @clientes);

    # nao tem nenhum habilitado, entao nao precisa nem criar a mensagem
    return unless @clientes;

    $schema2->txn_do(
        sub {
            my $message_row = $schema2->resultset('NotificationMessage')->create($message);

            $schema2->resultset('NotificationLog')->populate(
                [
                    [qw/cliente_id notification_message_id created_at/],
                    map {
                        [
                            $_->{cliente_id},
                            $message_row->id,
                            \'NOW()'
                        ]
                    } @clientes
                ]
            );
        }
    );

    return (
        clientes => \@clientes,
    );
}

sub new_notification_like {
    my (undef, $job, $type, $opts) = @_;

    my $schema2 = $job->app->schema2;    # mysql
    my $logger  = $job->app->log;

    # se o tweet nao existe mais, entao n precisa notificar
    my $tweet      = $schema2->resultset('Tweet')->find($opts->{tweet_id}) or return;
    my $has_parent = $tweet->parent_id ? 1 : 0;

    if ($tweet->cliente_id == $opts->{subject_id}) {
        $logger->info("skipping... tweet.cliente_id is same as subject_id...");
        return;
    }

    my $titles = {
        new_like => $has_parent ? 'curtiu seu comentário' : 'curtiu sua publicação',
    };
    my $prefs = {
        new_like => $has_parent ? 'NOTIFY_LIKES_POSTS_COMMENTED' : 'NOTIFY_LIKES_POSTS_CREATED',
    };
    my $icons = {
        new_like => 3,
    };
    my $preference_name = $prefs->{$type};
    my $icon            = $icons->{$type};

    my $content = $tweet->content;
    if ($tweet->disable_escape && $content =~ /\</) {
        $content = Mojo::DOM->new($content)->all_text;
    }
    if (length($content) > 100) {
        $content = substr($content, 0, 100) . '…';
    }

    my $comment = $opts->{comment};
    if (defined $comment && length($comment) > 100) {
        $comment = substr($comment, 0, 100) . '…';
    }

    my $message = {
        is_test => is_test() ? 1 : 0,
        title   => $titles->{$type},
        content => $content,
        meta    => to_json(
            {
                tweet_id   => $tweet->id,
                admin_mode => $opts->{admin_mode} // 0,
            }
        ),
        subject_id => $opts->{subject_id},
        created_at => \'now()',
        icon       => $icon,
    };

    my @clientes = $job->app->rs_user_by_preference($preference_name, '1')->search(
        {
            cliente_id => $tweet->cliente_id,
        }
    )->all;

    log_trace($preference_name, scalar @clientes);

    # nao tem nenhum habilitado, entao nao precisa nem criar a mensagem
    return unless @clientes;

    $schema2->txn_do(
        sub {
            my $message_row = $schema2->resultset('NotificationMessage')->create($message);

            $schema2->resultset('NotificationLog')->populate(
                [
                    [qw/cliente_id notification_message_id created_at/],
                    map {
                        [
                            $_->{cliente_id},
                            $message_row->id,
                            \'NOW()'
                        ]
                    } @clientes
                ]
            );
        }
    );

    return (
        clientes => \@clientes,
    );
}


sub new_notification_comment {
    my (undef, $job, $type, $opts) = @_;

    my $schema2 = $job->app->schema2;    # mysql
    my $logger  = $job->app->log;

    my $subject_id = $opts->{subject_id};

    # se o tweet nao existe mais, entao n precisa notificar
    # se o comentario nao existe mais, nao precisa notificar
    # se o root foi apagado, nao precisa notificar
    my $reply_to_tweet = $schema2->resultset('Tweet')->find($opts->{tweet_id}) or return;

    #my $new_tweet      = $schema2->resultset('Tweet')->find($opts->{comment_id}) or return;
    my $root_tweet = (
          $opts->{root_tweet_id} eq $opts->{tweet_id}
        ? $reply_to_tweet
        : $schema2->resultset('Tweet')->find($opts->{root_tweet_id})
    ) or return;

    my $icon = 5;

    my $content = $reply_to_tweet->content;
    if ($reply_to_tweet->disable_escape && $content =~ /\</) {
        $content = Mojo::DOM->new($content)->all_text;
    }
    if (length($content) > 100) {
        $content = substr($content, 0, 100) . '…';
    }

    my $comment = $opts->{comment};
    if (defined $comment && length($comment) > 100) {
        $comment = substr($comment, 0, 100) . '…';
    }
    $content = '❝' . $comment . '❞ na publicação ❝' . $content . '❞';

    # lista de quem recebeu push, pra limpar o cache do notifications
    my @clientes;
    $logger->info(sprintf "new_comment id %s in reply_to: %s", $opts->{comment_id}, $reply_to_tweet->id);

    $logger->info(sprintf "reply_to: %s root: %s", $reply_to_tweet->id, $root_tweet->id);
    $logger->info(
        sprintf "reply_to.cliente_id: %s root.cliente_id %s", $reply_to_tweet->cliente_id,
        $root_tweet->cliente_id
    );

    # lista todos os usuarios que comentaram no mesmo nivel daquele tweet, naquela thread
    # ou que é o post root (dono)
    # ou quem foi que criou o comentario que recebeu o subcomentario
    my @ntf_clientes_ids = map { $_->{cliente_id} } $schema2->resultset('Tweet')->search(
        {
            '-or' => [
                {'me.parent_id' => $reply_to_tweet->id},
                {'me.id'        => $root_tweet->id},
                {'me.id'        => $reply_to_tweet->id},
            ]
        },
        {
            columns      => ['me.cliente_id'],
            group_by     => \'1',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;

    my $message_cache = {};
    foreach my $user_id (@ntf_clientes_ids) {
        if ($user_id == $subject_id) {
            $logger->info("skipping cliente_id: $user_id - same as subject_id");
            next;    # pula o proprio sujeito (se for anonimo, vai enviar mesmo assim)
        }

        $logger->info("notify cliente_id: $user_id");

        my $is_creator = $user_id == $root_tweet->cliente_id ? 1 : 0;

        my $title = $is_creator ? 'comentou sua publicação'       : 'comentou seu comentário';
        my $pref  = $is_creator ? 'NOTIFY_COMMENTS_POSTS_CREATED' : 'NOTIFY_COMMENTS_POSTS_COMMENTED';

        $logger->info("testing $pref for user $user_id");

        my $cliente = $job->app->rs_user_by_preference($pref, '1')->search(
            {
                cliente_id => $user_id,
            }
        )->next;
        if (!$cliente) {
            $logger->info("skipping cliente_id: $user_id - notifications disabled");
            next;    # nao quer receber notificacao
        }

        push @clientes, $cliente;

        $schema2->txn_do(
            sub {

                my $message_row = $message_cache->{$is_creator};
                if (!$message_row) {
                    my $message = {
                        is_test => is_test() ? 1 : 0,
                        title   => $title,
                        content => $content,
                        meta    => to_json(
                            {
                                tweet_id   => $reply_to_tweet->id,
                                comment_id => $opts->{comment_id},
                                admin_mode => $opts->{admin_mode} // 0,
                            }
                        ),
                        subject_id => $opts->{subject_id},
                        created_at => \'now()',
                        icon       => $icon,
                    };
                    $message_row = $schema2->resultset('NotificationMessage')->create($message);
                    $logger->info(sprintf "new notification message %d", $message_row->id);
                }

                my $log = $schema2->resultset('NotificationLog')->create(
                    {
                        cliente_id              => $user_id,
                        notification_message_id => $message_row->id,
                        created_at              => \'now()',

                    }
                );
                $logger->info(sprintf "new notification message log %d", $log->id);
            }
        );


    }

    return (
        clientes => \@clientes,
    );
}

sub new_notification_post_local_badge_holder {
    my (undef, $job, $type, $opts) = @_;

    my $schema2 = $job->app->schema2;    # mysql
    my $logger  = $job->app->log;

    # Basic checks
    return $job->fail("Missing poster_cep_cidade in opts") unless $opts->{poster_cep_cidade};
    return $job->fail("Missing subject_id in opts")        unless $opts->{subject_id};
    return $job->fail("Missing tweet_id in opts")          unless $opts->{tweet_id};

    my $poster_cep_cidade = $opts->{poster_cep_cidade};
    my $subject_id        = $opts->{subject_id};          # This is the poster's ID

    # Get the tweet, ensure it's a valid target (published, top-level)
    my $tweet = $schema2->resultset('Tweet')->find($opts->{tweet_id});
    unless ($tweet) {
        $logger->info("Badge Notification ($type): Tweet $opts->{tweet_id} not found. Skipping.");
        return ();                                        # Return empty list, job will finish
    }
    if ($tweet->parent_id) {
        $logger->info("Badge Notification ($type): Tweet $opts->{tweet_id} is a comment. Skipping.");
        return ();
    }
    if ($tweet->status ne 'published') {
        $logger->info(
            "Badge Notification ($type): Tweet $opts->{tweet_id} status is not published ($tweet->status). Skipping.");
        return ();
    }
    if ($tweet->anonimo) {
        $logger->info(
            "Badge Notification ($type): Tweet $opts->{tweet_id} is anonymous. Skipping (should have been caught earlier, but safety check)."
        );
        return ();
    }


    my $preference_name = 'NOTIFY_POST_FROM_BADGE_HOLDER_IN_MY_CITY';
    my $icon            = 2;                                            # Choose an appropriate icon ID

    # Prepare message content (similar to other handlers)
    my $content = $tweet->content;
    if ($tweet->disable_escape && $content =~ /\</) {
        $content = Mojo::DOM->new($content)->all_text;
    }
    if (length($content) > 100) {
        $content = substr($content, 0, 100) . '…';
    }

    # Maybe get poster's name? Requires another lookup. Let's keep it simple for now.
    # my $poster = $schema2->resultset('Cliente')->find($subject_id);
    # my $poster_name = $poster ? $poster->apelido : 'Alguém';

    my $message = {
        is_test => is_test() ? 1 : 0,
        title   => 'Voluntária da sua região fez uma nova publicação',  # Could be: "$poster_name postou na sua cidade!"
        content => $content,
        meta    => to_json(
            {
                tweet_id   => $tweet->id,
                admin_mode => $opts->{admin_mode} // 0,
            }
        ),
        subject_id => $subject_id,                                      # The user who posted
        created_at => \'now()',
        icon       => $icon,
    };

    # Find users in the same city who want this notification, excluding the poster
    my @clientes = $job->app->rs_user_by_preference($preference_name, '1')->search(
        {
            'cliente.cep_cidade' => $poster_cep_cidade,
            'me.cliente_id'      => {'!=' => $subject_id},
        },
        {
            columns => ['me.cliente_id'],
            join    => 'cliente',
        }
    )->all;

    log_trace("Found " . scalar(@clientes) . " users for $preference_name in city '$poster_cep_cidade'");

    return unless @clientes;    # No users enabled, don't create message

    # Create the notification message and logs
    # NOTE: This creates ONE message shared by all recipients of this specific job run.
    # If two different badge holders post in the same city close together, two messages will be created.
    my $message_row;
    eval {
        $schema2->txn_do(
            sub {
                $message_row = $schema2->resultset('NotificationMessage')->create($message);
                $logger->info("Created NotificationMessage ID: " . $message_row->id . " for $type");

                $schema2->resultset('NotificationLog')->populate(
                    [
                        [qw/cliente_id notification_message_id created_at/],
                        map {
                            [
                                $_->{cliente_id},
                                $message_row->id,
                                \'NOW()'
                            ]
                        } @clientes
                    ]
                );
                $logger->info(
                    "Populated NotificationLog for " . scalar(@clientes) . " users for message " . $message_row->id);
            }
        );
    };
    if ($@) {
        $logger->error("Failed to create badge notification ($type) for tweet $opts->{tweet_id}: $@");

        # Let Minion handle retry based on job settings
        $job->fail("DB transaction failed: $@");
        return ();    # Explicitly return nothing on failure
    }


    return (
        clientes => \@clientes,    # Return list of users who received it for cache clearing
    );
}

# <<< NEW HANDLER 2 - REVISED >>>
sub new_notification_post_linked_city_badge_holder {
    my (undef, $job, $type, $opts) = @_;

    my $schema2 = $job->app->schema2;    # mysql
    my $logger  = $job->app->log;

    # Basic checks
    return $job->fail("Missing linked_cep_cidades in opts")
      unless $opts->{linked_cep_cidades} && ref $opts->{linked_cep_cidades} eq 'ARRAY';
    return $job->fail("Missing subject_id in opts") unless $opts->{subject_id};
    return $job->fail("Missing tweet_id in opts")   unless $opts->{tweet_id};

    # double check, already done before enqueuing, não usamos mas podemos usar pra avisar no texto
    # da notificação
    my $poster_cep_cidade = $opts->{poster_cep_cidade};
    return $job->fail("Missing poster_cep_cidade in opts") unless defined $poster_cep_cidade;

    my $linked_cep_cidades = $opts->{linked_cep_cidades};
    my $subject_id         = $opts->{subject_id};           # Poster's ID

    # Check if there are actually cities to notify about
    unless (@$linked_cep_cidades) {
        $logger->info("Badge Notification ($type): No linked cities provided. Skipping.");
        return ();
    }

    # Get the tweet, ensure it's a valid target (published, top-level)
    my $tweet = $schema2->resultset('Tweet')->find($opts->{tweet_id});
    unless ($tweet) {
        $logger->info("Badge Notification ($type): Tweet $opts->{tweet_id} not found. Skipping.");
        return ();
    }
    if ($tweet->parent_id) {
        $logger->info("Badge Notification ($type): Tweet $opts->{tweet_id} is a comment. Skipping.");
        return ();
    }
    if ($tweet->status ne 'published') {
        $logger->info(
            "Badge Notification ($type): Tweet $opts->{tweet_id} status is not published ($tweet->status). Skipping.");
        return ();
    }
    if ($tweet->anonimo) {
        $logger->info("Badge Notification ($type): Tweet $opts->{tweet_id} is anonymous. Skipping.");
        return ();
    }

    my $preference_name = 'NOTIFY_POST_FROM_BADGE_HOLDER_FOR_LINKED_CITY';
    my $icon            = 5;

    # Prepare message content
    my $content = $tweet->content;
    if ($tweet->disable_escape && $content =~ /\</) {
        $content = Mojo::DOM->new($content)->all_text;
    }
    if (length($content) > 100) {
        $content = substr($content, 0, 100) . '…';
    }

    # Title might need refinement. "Relevant" is vague.
    # Maybe include the city name? That requires knowing *which* city matched *this* user.
    # Keep it generic for now.
    my $message = {
        is_test => is_test() ? 1 : 0,
        title   => 'Usuária da sua região fez uma nova publicação',
        content => $content,
        meta    => to_json(
            {
                tweet_id   => $tweet->id,
                admin_mode => $opts->{admin_mode} // 0,
            }
        ),
        subject_id => $subject_id,
        created_at => \'now()',
        icon       => $icon,
    };

    # Find users in the relevant cities who want this notification,
    my $search_cond = {
        'cliente.cep_cidade' => {-in  => $linked_cep_cidades},
        'me.cliente_id'      => {'!=' => $subject_id},

        'badge.linked_cep_cidade' => {-in => $linked_cep_cidades},
    };

    my @clientes = $job->app->rs_user_by_preference($preference_name, '1')->search(
        $search_cond,
        {
            columns => ['me.cliente_id'],
            join    => {
                'cliente' => {cliente_tags => 'badge'},
            }
        }
    )->all;

    log_trace("Found "
          . scalar(@clientes)
          . " users for $preference_name in linked cities ["
          . (join ',', @$linked_cep_cidades)
          . "] ");

    return unless @clientes;

    # Create the notification message and logs
    my $message_row;
    eval {
        $schema2->txn_do(
            sub {
                $message_row = $schema2->resultset('NotificationMessage')->create($message);
                $logger->info("Created NotificationMessage ID: " . $message_row->id . " for $type");

                $schema2->resultset('NotificationLog')->populate(
                    [
                        [qw/cliente_id notification_message_id created_at/],
                        map {
                            [
                                $_->{cliente_id},
                                $message_row->id,
                                \'NOW()'
                            ]
                        } @clientes
                    ]
                );
                $logger->info(
                    "Populated NotificationLog for " . scalar(@clientes) . " users for message " . $message_row->id);
            }
        );
    };
    if ($@) {
        $logger->error("Failed to create badge notification ($type) for tweet $opts->{tweet_id}: $@");
        $job->fail("DB transaction failed: $@");
        return ();
    }


    return (
        clientes => \@clientes,
    );
}

1;
