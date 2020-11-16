package Penhas::Minion::Tasks::NewNotification;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Digest::MD5 qw/md5_hex/;
use Penhas::Uploader;
use Mojo::DOM;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(new_notification => \&new_notification);
}

sub new_notification {
    my ($job, $type, $opts) = @_;

    log_trace("minion:new_notification", $type);

    my $known_types = {
        new_comment => 'new_notification_timeline',
        new_like    => 'new_notification_timeline',
    };

    my $subname = $known_types->{$type} || die "notification type $type is not known";

    my (%ret) = __PACKAGE__->$subname($job, $type, $opts);

    # reseta o cache de quem recebeu notificação
    $job->app->user_notifications_clear_cache($_->{cliente_id}) for @{$ret{clientes} || []};

    return $job->finish(1);

}

sub new_notification_timeline {
    my (undef, $job, $type, $opts) = @_;

    my $schema2 = $job->app->schema2;    # mysql
    my $logger  = $job->app->log;

    # se o tweet nao existe mais, entao n precisa notificar
    my $tweet      = $schema2->resultset('Tweet')->find($opts->{tweet_id}) or return;
    my $has_parent = $tweet->parent_id ? 1 : 0;

    my $titles = {
        new_comment => $has_parent ? 'comentou seu comentário' : 'comentou sua publicação',
        new_like    => $has_parent ? 'curtiu seu comentário'   : 'curtiu sua publicação',
    };
    my $prefs = {
        new_comment => $has_parent ? 'NOTIFY_COMMENTS_POSTS_COMMENTED' : 'NOTIFY_COMMENTS_POSTS_CREATED',
        new_like    => $has_parent ? 'NOTIFY_LIKES_POSTS_COMMENTED'    : 'NOTIFY_LIKES_POSTS_CREATED',
    };
    my $icons = {
        new_comment => 2,    # icones na pasta public/i/
        new_like    => 3,
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

    if ($type eq 'new_comment') {
        $content = '❝' . $comment . '❞ na publicação ' . $content;
    }

    my $message = {
        is_test    => is_test() ? 1 : 0,
        title      => $titles->{$type},
        content    => $content,
        meta       => to_json({tweet_id => $tweet->id}),
        subject_id => $opts->{subject_id},
        created_at => \'now(6)',
        icon       => $icon,
    };
    my @subjects;

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
                            \'NOW(6)'
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

1;
