package Penhas::Helpers::Notifications;
use common::sense;
use Carp qw/confess croak/;
use utf8;
use JSON;
use Penhas::Logger;
use Penhas::Utils;
use Scope::OnExit;

my $ntf_cache_key = 'unreadntfcount:';

sub setup {
    my $c = shift;

    $c->helper(user_notifications_clear_cache  => \&user_notifications_clear_cache);
    $c->helper(user_notifications_unread_count => \&user_notifications_unread_count);
    $c->helper(user_notifications              => \&user_notifications);
}

sub user_notifications_unread_count {
    my ($c, $user_id) = @_;

    confess '$user_id is not defined' unless defined $user_id;

    return $c->kv->redis_get_cached_or_execute(
        $ntf_cache_key . $user_id,
        86400,    # 24 hours
        sub {
            my $read_until = $c->schema2->resultset('ClientesAppNotification')->search({cliente_id => $user_id})
              ->get_column('read_until')->next();

            my $count = $c->schema2->resultset('NotificationLog')->search(
                {
                    'me.cliente_id' => $user_id,
                    ($read_until ? ('me.created_at' => {'>' => $read_until}) : ())
                },
                {
                    join => 'cliente',
                }
            )->count;

            return $count;
        }
    );

}

sub user_notifications_clear_cache {
    my ($c, $user_id) = @_;

    confess '$user_id is not defined' unless defined $user_id;

    return $c->kv->redis_del($ntf_cache_key . $user_id);
}

sub user_notifications {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $rows     = $opts{rows} || 100;
    $rows = 10 if !is_test() && ($rows > 1000 || $rows < 10);

    my $older_than;
    my $not_in;
    if ($opts{next_page}) {
        my $tmp = eval { $c->decode_jwt($opts{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'NFTP';
        $older_than = $tmp->{ot};
        $not_in     = $tmp->{not_in};
    }

    my $filter = {
        'me.cliente_id' => $user_obj->id,
        (
            $older_than
            ? (
                'me.created_at' => {'<=' => $older_than},
                ($not_in ? ('me.id' => {'not in' => $not_in}) : ())
              )
            : ()
        ),
    };

    my $rs = $c->schema2->resultset('NotificationLog')->search(
        $filter,
        {
            prefetch     => ['notification_message'],
            order_by     => \'me.created_at DESC',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            rows         => $rows + 1,
        }
    );

    my @rows      = $rs->all;
    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }
    my $last_timestamp  = @rows ? $rows[-1]{created_at} : undef;
    my $first_timestamp = @rows ? $rows[0]{created_at}  : undef;

    my @not_in;
    my @output_rows;
    my @load_users;
    my @load_users_chat;    # forcar carregar o chat, mesmo se estiverem em modo anônimo
    my $blocked_users = "," . $user_obj->timeline_clientes_bloqueados_ids() . ',';

    foreach my $r (@rows) {
        my $notification_message = $r->{notification_message};
        my $meta                 = $notification_message->{meta} ? from_json($notification_message->{meta}) : {};
        push @not_in, $r->{id} if $r->{created_at} eq $last_timestamp;

        my $subject_id = $notification_message->{subject_id};
        next if $subject_id && index($blocked_users, ",$subject_id,") >= 0;

        push @load_users,      $subject_id if $subject_id;
        push @load_users_chat, $subject_id if $subject_id && $meta->{chat};

        $notification_message->{icon} ||= 0;

        push @output_rows, {
            content     => remove_pi($notification_message->{content}),
            title       => $notification_message->{title},
            time        => pg_timestamp2iso_8601($notification_message->{created_at}),
            icon        => $ENV{DEFAULT_NOTIFICATION_ICON} . '/' . $notification_message->{icon} . '.svg',
            _subject_id => $subject_id,
            _meta       => $meta,
        };
    }

    my %subjects = map { ($_->{id} => $_) } $c->schema2->resultset('Cliente')->search(
        {
            'me.id'                 => {'in' => \@load_users},
            'me.modo_anonimo_ativo' => 0,
            'me.status'             => 'active',
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => ['id', 'apelido'],
        }
    )->all;

    foreach my $r (@output_rows) {
        my $subject_id = $r->{_subject_id};
        my $subject    = $subjects{$subject_id};

        # nao tem, eh anonimo ou postado
        if (!defined $subject_id) {
            $r->{name} = 'PenhaS';
        }
        elsif ($subject_id == -1) {
            $r->{name}  = 'Suporte PenhaS';
            $r->{title} = 'respondeu sua mensagem';
        }
        elsif ($subject) {
            $r->{name} = $subject->{apelido};
        }
        else {
            $r->{name} = 'Anônimo';
        }
    }

    my %subjects_anon = map { ($_->{id} => $_) } $c->schema2->resultset('Cliente')->search(
        {
            '-and' => [
                {'me.id' => {'in'     => \@load_users_chat}},
                {'me.id' => {'not in' => [keys %subjects]}},
            ],
            'me.status' => 'active',
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => ['id', 'apelido'],
        }
    )->all;

    foreach my $r (@output_rows) {
        next unless $r->{_meta}{chat};
        next if $r->{name} && $r->{name} ne 'Anônimo';

        my $subject_id = $r->{_subject_id};
        my $subject    = $subjects_anon{$subject_id};

        if ($subject) {
            $r->{name} = $subject->{apelido};
            log_trace("anon_user:" . $r->{name});
        }
        else {
            $r->{name} = 'Usuário removido';
        }
    }

    my $next_page = $c->encode_jwt(
        {
            iss    => 'NFTP',
            not_in => \@not_in,
            ot     => $last_timestamp,
        },
        1
    );

    # nao eh paginado, e tem resultados
    # atualiza o "read_until" pra zerar (ou não) o contador
    if (!$opts{next_page} && $first_timestamp) {

        my $updated_timestamp = $c->schema2->resultset('ClientesAppNotification')->search({cliente_id => $user_obj->id})
          ->update({read_until => $first_timestamp});
        if ($updated_timestamp == 0) {

            # nao tinha linha.. precisa inserir
            my ($locked, $locked_key)
              = $c->kv->lock_and_wait('ClientesAppNotificationIns' . $user_obj->id, 2)
              ;    # aguarda por 2 segundos no maximo
            on_scope_exit { $c->kv->redis->del($locked_key) };

            if ($locked) {
                $c->schema2->resultset('ClientesAppNotification')->create(
                    {
                        cliente_id => $user_obj->id,
                        read_until => $first_timestamp,
                    }
                );
            }      # else: bem, nos tentamos...
        }

        $c->user_notifications_clear_cache($user_obj->id);
    }

    my ($meta, $subject_id);

    # removendo chaves privadas no final e criando deep-links
    foreach my $r (@output_rows) {

        $meta       = delete $r->{_meta};
        $subject_id = delete $r->{_subject_id};

        if ($meta->{chat}) {
            if ($subject_id == -1) {
                $r->{expand_screen} = '/mainboard/chat/' . $user_obj->support_chat_auth();
            }
            else {
                my $open_chat = eval { $c->chat_open_session(user_obj => $user_obj, cliente_id => $subject_id) };
                if ($@) {
                    $c->log->error("chat_open_session returned error: " . $c->app->dumper($@));
                }
                $r->{expand_screen} = '/mainboard/chat/' . $open_chat->{chat_auth}
                  if $open_chat && ref $open_chat eq 'HASH';
                log_trace("expand_screen=" . $subject_id);
            }
        }
        elsif ($meta->{tweet_id} && $meta->{comment_id}) {
            $r->{expand_screen} = '/mainboard/tweet/' . $meta->{tweet_id} . '?comment_id=' . $meta->{comment_id};
        }
        elsif ($meta->{tweet_id}) {
            $r->{expand_screen} = '/mainboard/tweet/' . $meta->{tweet_id};
        }
    }

    return {
        rows      => \@output_rows,
        has_more  => $has_more,
        next_page => $has_more ? $next_page : undef,
    };
}

1;
