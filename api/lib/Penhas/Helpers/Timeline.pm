package Penhas::Helpers::Timeline;
use common::sense;
use Carp qw/croak/;
use utf8;
use Penhas::KeyValueStorage;
use Scope::OnExit;

use JSON;
use Penhas::Logger;
use Penhas::Utils;

sub kv { Penhas::KeyValueStorage->instance }

sub setup {
    my $self = shift;

    $self->helper('add_tweet'    => sub { &add_tweet(@_) });
    $self->helper('delete_tweet' => sub { &delete_tweet(@_) });
    $self->helper('like_tweet'   => sub { &like_tweet(@_) });
    $self->helper('report_tweet' => sub { &report_tweet(@_) });
    $self->helper('list_tweets'  => sub { &list_tweets(@_) });

}

sub like_tweet {
    my ($c, %opts) = @_;

    my $user = $opts{user} or croak 'missing user';
    my $id   = $opts{id}   or croak 'missing id';

    slog_info(
        'like_tweet %s',
        $id
    );

    my $lock = "tweet_id:$id";
    kv->lock_and_wait($lock);
    on_scope_exit { kv->unlock($lock) };

    my $already_liked = $c->directus->search_one(
        table => 'tweets_likes',
        form  => {
            'filter[tweet_id][eq]'   => $id,
            'filter[cliente_id][eq]' => $user->{id},
        }
    );

    my $likes;
    if (!$already_liked) {
        $c->directus->create(
            table => 'tweets_likes',
            form  => {
                tweet_id   => $id,
                cliente_id => $user->{id}
            }
        );

        my $current_likes = $c->directus->search_one(
            table => 'tweets',
            form  => {
                form => {
                    'filter[id][eq]' => $id,
                }
            }
        );
        $likes = $current_likes->{qtde_likes} + 1;
        $c->directus->update(
            table => 'tweets',
            id    => $id,
            form  => {qtde_likes => $likes}
        );
    }
    else {
        my $current_likes = $c->directus->search_one(
            table => 'tweets',
            form  => {
                form => {
                    'filter[id][eq]' => $id,
                }
            }
        );
        $likes = $current_likes->{qtde_likes};
    }

    return {qtde_likes => $likes};
}

sub delete_tweet {
    my ($c, %opts) = @_;

    my $user = $opts{user} or croak 'missing user';
    my $id   = $opts{id}   or croak 'missing id';

    slog_info(
        'del_tweet %s',
        $id,
    );

    my $item = $c->directus->search_one(
        table => 'tweets',
        form  => {
            form => {
                'filter[id][eq]'         => $id,
                'filter[cliente_id][eq]' => $user->{id},
            }
        }
    );
    die {
        message => 'Não foi possível encontrar a postagem.',
        error   => 'tweet_not_found'
    } if !$item;

    if ($item->{status} eq 'published') {
        $c->directus->update(
            table => 'tweets',
            id    => $item->{id},
            form  => {
                status => 'deleted',
            }
        );
    }

    return 1;
}

sub add_tweet {
    my ($c, %opts) = @_;

    my $user    = $opts{user}    or croak 'missing user';
    my $content = $opts{content} or croak 'missing content';
    my $reply_to = $opts{reply_to};

    # die {message => 'O conteúdo precisa ser menor que 500 caracteres', error => 'tweet_too_long'}
    #   if length $content > 500; Validado no controller
    slog_info(
        'add_tweet content=%s reply_to=%s',
        $content,
        $reply_to || ''
    );

    # captura o horario atual, e depois, fazemos um contador unico (controlado pelo redis),
    # o redis lembra por 60 segundos de "cada segundo tweetado", just in case
    # tenha algum retry lentidao na rede e varios tweets tentando processar.
  AGAIN:
    my $now     = DateTime->now;
    my $base    = substr($now->ymd(''), 2) . 'T' . $now->hms('');
    my $cur_seq = kv->local_inc_then_expire(
        key     => $base,
        expires => 60
    );

    # permite até 9999 tweets em 1 segundo, acho que ta ok pra este app!
    # se tiver tudo isso de tweet em um segundo, aguarda o proximo segundo!
    if ($cur_seq == 9999) {
        sleep 1;
        goto AGAIN;
    }
    my $id = $base . sprintf('%04d', $cur_seq);

    my $lock = "tweet_id:$reply_to";
    kv->lock_and_wait($lock)            if $reply_to;
    on_scope_exit { kv->unlock($lock) } if $reply_to;

    my $tweet = $c->directus->create(
        table => 'tweets',
        form  => {
            status       => 'published',
            id           => $id,
            content      => $content,
            'cliente_id' => $user->{id},
            anonimo      => $user->{modo_anonimo_ativo} ? 1 : 0,
            parent_id    => $reply_to,
            created_at   => $now->datetime(' '),
        }
    );
    die 'tweet_id missing' unless $tweet->{data}{id};

    if ($reply_to) {
        my $current = $c->directus->search_one(
            table => 'tweets',
            form  => {
                form => {
                    'filter[id][eq]' => $id,
                }
            }
        );
        $c->directus->update(
            table => 'tweets',
            id    => $current->{id},
            form  => {qtde_comentarios => $current->{qtde_comentarios} + 1}
        ) if $current;

    }

    return $tweet->{data};
}

sub report_tweet {
    my ($c, %opts) = @_;

    my $user        = $opts{user}   or croak 'missing user';
    my $reason      = $opts{reason} or croak 'missing reason';
    my $reported_id = $opts{id}     or croak 'missing id';

    slog_info(
        'report_tweet reported_id=%s, reason=%s',
        $reported_id, $reason,
    );

    my $lock = "tweet_id:$reported_id";
    kv->lock_and_wait($lock);
    on_scope_exit { kv->unlock($lock) };

    my $report = $c->directus->create(
        table => 'tweets_reports',
        form  => {
            reason      => $reason,
            cliente_id  => $user->{id},
            reported_id => $reported_id,
            created_at  => DateTime->now->datetime(' '),
        }
    );
    die 'id missing' unless $report->{data}{id};

    my $current = $c->directus->search_one(
        table => 'tweets',
        form  => {
            form => {
                'filter[id][eq]' => $reported_id,
            }
        }
    );
    $c->directus->update(
        table => 'tweets',
        id    => $current->{id},
        form  => {qtde_reportado => $current->{qtde_reportado} + 1}
    ) if $current;

    return $report->{data};
}

sub list_tweets {
    my ($c, %opts) = @_;

    my $rows = $opts{rows} || 10;
    $rows = 10 if $rows > 100 || $rows < 1;

    my $user = $opts{user} or croak 'missing user';

    slog_info(
        'list_tweets after=%s before=%s parent_id=%s rows=%s',
        $opts{after}     || '',
        $opts{before}    || '',
        $opts{parent_id} || '',
        $rows,
    );

    my $cond = {
        'cliente.status' => 'active',
        'me.escondido'   => 'false',
        'me.status'      => 'published',

        '-and' => [
            ($opts{after}  ? ({'me.id' => {'>' => $opts{after}}})  : ()),
            ($opts{before} ? ({'me.id' => {'<' => $opts{before}}}) : ()),
            (
                $opts{parent_id}
                ? ({parent_id => $opts{parent_id}})
                : ({parent_id => undef})              # nao eh pra montar comentarios na timeline principal
            ),
        ],
    };
    delete $cond->{'-and'} if scalar $cond->{'-and'}->@* == 0;

    my @rows = $c->schema2->resultset('Tweet')->search(
        $cond,
        {
            join       => 'cliente',
            order_by   => [{'-desc' => 'me.id'}],
            rows       => $rows + 1,
            '+columns' => [
                {cliente_apelido            => 'cliente.apelido'},
                {cliente_modo_anonimo_ativo => 'cliente.modo_anonimo_ativo'},
                {cliente_avatar_url         => 'cliente.avatar_url'}

            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;
    my $has_more = scalar @rows > $rows ? 1 : 0;
    pop @rows if $has_more;

    my $avatar_anonimo = $ENV{AVATAR_ANONIMO_URL};
    my $avatar_default = $ENV{AVATAR_PADRAO_URL};

    my @tweets;
    my @unique_ids;
    foreach my $tweet (@rows) {

        push @unique_ids, $tweet->{id};

        my $anonimo = $tweet->{anonimo} || $tweet->{cliente_modo_anonimo_ativo};

        push @tweets, {
            meta => {
                owner => $user->{id} == $tweet->{cliente_id} ? 1 : 0,
            },
            id               => $tweet->{id},
            content          => $tweet->{content},
            anonimo          => $anonimo ? 1 : 0,
            qtde_likes       => $tweet->{qtde_likes},
            qtde_comentarios => $tweet->{qtde_comentarios},
            media            => [],
            icon             => $anonimo ? $avatar_anonimo : $tweet->{cliente_avatar_url} || $avatar_default,
            name             => $anonimo ? 'Anônimo' : $tweet->{cliente_apelido},
            created_at       => $tweet->{created_at},
            ($anonimo ? () : (cliente_id => $tweet->{cliente_id})),

        };

    }

    my %already_liked = map { $_->{tweet_id} => 1 } $c->schema2->resultset('TweetLikes')->search(
        {cliente_id => $user->{id}, tweet_id => {'in' => \@unique_ids}},
        {
            columns      => ['tweet_id'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;
    foreach my $tweet (@tweets) {
        $tweet->{meta}{liked} = $already_liked{$tweet->{id}} || 0;
    }

    return {
        tweets   => \@tweets,
        has_more => $has_more,
    };
}


1;
