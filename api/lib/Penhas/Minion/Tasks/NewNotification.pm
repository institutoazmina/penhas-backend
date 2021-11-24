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
        new_message => 'new_notification_chat'
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
        is_test    => is_test() ? 1 : 0,
        title      => $titles->{$type},
        content    => $content,
        meta       => to_json({tweet_id => $tweet->id}),
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

    my $icon = 2;    # icones na pasta public/i/

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

    $logger->info(sprintf "new_comment, reply_to: %s root: %s", $reply_to_tweet->id, $root_tweet->id);
    $logger->info(
        sprintf "new_comment, reply_to.cliente_id: %s root.cliente_id %s", $reply_to_tweet->cliente_id,
        $root_tweet->cliente_id
    );

    # lista todos os usuarios que comentaram no mesmo nivel daquele tweet, naquela thread
    # ou que é o post root (post)
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
    $logger->info("ntf_clientes_ids: @ntf_clientes_ids");
    my $x = $schema2->resultset('Tweet')->search({
        parent_id => $reply_to_tweet->id
    })->count;
    use DDP; p $x;

    $x = [$schema2->resultset('Tweet')->search({
        parent_id => $reply_to_tweet->id
    })->all];
    use DDP; p $x;

    my $message_cache = {};
    foreach my $user_id (@ntf_clientes_ids) {
        $logger->info("skipping cliente_id: $user_id - same as subject_id"), next
          if $user_id == $subject_id;    # pula o proprio sujeito (se for anonimo, vai enviar mesmo assim)

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
        $logger->info("skipping cliente_id: $user_id - notifications disabled"), next
          unless $cliente;    # nao quer receber notificacao

        push @clientes, $cliente;

        $schema2->txn_do(
            sub {

                my $message_row = $message_cache->{$is_creator};
                if (!$message_row) {
                    my $message = {
                        is_test    => is_test() ? 1 : 0,
                        title      => $title,
                        content    => $content,
                        meta       => to_json({tweet_id => $reply_to_tweet->id, comment_id => $opts->{comment_id}}),
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

1;
