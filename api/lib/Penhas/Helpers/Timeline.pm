package Penhas::Helpers::Timeline;
use common::sense;
use Carp qw/croak/;
use utf8;
use Penhas::KeyValueStorage;
use Scope::OnExit;
use Digest::MD5 qw/md5_hex/;
use Mojo::Util qw/trim xml_escape url_escape/;

use JSON;
use Penhas::Logger;
use Penhas::Utils;
use List::Util '1.54' => qw/sample/;

our $ForceFilterClientes;
sub kv { Penhas::KeyValueStorage->instance }

sub setup {
    my $self = shift;

    $self->helper('add_tweet'             => sub { &add_tweet(@_) });
    $self->helper('delete_tweet'          => sub { &delete_tweet(@_) });
    $self->helper('like_tweet'            => sub { &like_tweet(@_) });
    $self->helper('report_tweet'          => sub { &report_tweet(@_) });
    $self->helper('list_tweets'           => sub { &list_tweets(@_) });
    $self->helper('add_tweets_highlights' => sub { &add_tweets_highlights(@_) });
    $self->helper('add_tweets_news'       => sub { &add_tweets_news(@_) });

}

sub like_tweet {
    my ($c, %opts) = @_;

    my $user = $opts{user} or croak 'missing user';
    my $id   = $opts{id}   or croak 'missing id';
    my $remove = $opts{remove};

    croak 'missing remove' unless defined $remove;

    slog_info(
        'like_tweet %s %s',
        $remove ? 'Remove' : 'Add',
        $id,
    );

    my $lock = "likes:user:" . $user->{id};
    kv->lock_and_wait($lock);
    on_scope_exit { kv->unlock($lock) };

    my $rs = $c->schema2->resultset('Tweet');

    my $likes_rs = $c->schema2->resultset('TweetLikes');

    my $already_liked = $likes_rs->search(
        {
            'tweet_id'   => $id,
            'cliente_id' => $user->{id},
        }
    )->next;

    if (!$already_liked && !$remove) {
        $likes_rs->create(
            {
                tweet_id   => $id,
                cliente_id => $user->{id}
            }
        );

        $rs->search({id => $id})->update(
            {
                qtde_likes => \'qtde_likes+1',
            }
        );
    }
    elsif ($remove && $already_liked) {

        $already_liked->delete;

        $rs->search({id => $id})->update(
            {
                qtde_likes => \'qtde_likes-1',
            }
        );
    }

    my $reference = $rs->search(
        {
            'me.id' => $id,
        },
        {
            join       => 'cliente',
            '+columns' => [
                {cliente_apelido            => 'cliente.apelido'},
                {cliente_modo_anonimo_ativo => 'cliente.modo_anonimo_ativo'},
                {cliente_avatar_url         => 'cliente.avatar_url'}

            ],
        }
    )->next;

    return {tweet => &_get_tweet_by_id($c, $user, $reference->id)};
}

sub delete_tweet {
    my ($c, %opts) = @_;

    my $user = $opts{user} or croak 'missing user';
    my $id   = $opts{id}   or croak 'missing id';

    slog_info(
        'del_tweet %s',
        $id,
    );
    my $rs = $c->schema2->resultset('Tweet');

    my $item = $rs->search(
        {
            id         => $id,
            cliente_id => $user->{id},
            status     => 'published',
        }
    )->next;
    die {
        message => 'Não foi possível encontrar a postagem.',
        error   => 'tweet_not_found'
    } unless $item;

    $item->update(
        {
            status => 'deleted',
        }
    );

    if ($item->parent_id) {
        $rs->search(
            {
                id => $item->parent_id,
            }
        )->update(
            {
                ultimo_comentario_id => \[
                    "(SELECT max(id) FROM tweets t WHERE t.parent_id = ? AND t.status = 'published')",
                    $item->parent_id
                ],
                qtde_comentarios => \'qtde_comentarios - 1'
            }
        );
    }

    return 1;
}

sub add_tweet {
    my ($c, %opts) = @_;

    my $user    = $opts{user}    or croak 'missing user';
    my $content = $opts{content} or croak 'missing content';
    my $media_ids = $opts{media_ids};
    my $reply_to  = $opts{reply_to};

    if ($media_ids) {
        $media_ids = [split ',', $media_ids];
        foreach my $media_id ($media_ids->@*) {
            die {error => 'media_id', message => 'invalid uuid v4'}
              unless is_uuid_v4($media_id);
        }

        my $count = $c->schema2->resultset('MediaUpload')->search(
            {
                cliente_id => $user->{id},
                id         => {'in' => $media_ids},
            }
        )->count;

        # precisa ser o dono de todos
        if ($count != scalar $media_ids->@*) {
            die {error => 'media_id', message => 'media_id not found'};
        }
    }

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
    my $rs = $c->schema2->resultset('Tweet');

    my $tweet = $rs->create(
        {
            status       => 'published',
            id           => $id,
            content      => $content,
            'cliente_id' => $user->{id},
            anonimo      => $user->{modo_anonimo_ativo} ? 1 : 0,
            parent_id    => $reply_to,
            created_at   => $now->datetime(' '),
            media_ids    => $media_ids ? to_json($media_ids) : undef,
        }
    );

    if ($reply_to) {

        $rs->search({id => $reply_to})->update(
            {
                qtde_comentarios     => \'qtde_comentarios + 1',
                ultimo_comentario_id => \[
                    '(case when ultimo_comentario_id is null OR ultimo_comentario_id < ? then ? else ultimo_comentario_id end)',
                    $tweet->id, $tweet->id
                ],
            }
        );
    }

    return &_get_tweet_by_id($c, $user, $tweet->id);
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
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $user = $opts{user} or croak 'missing user';

    slog_info(
        'list_tweets after=%s before=%s parent_id=%s id=%s rows=%s tags=%s',
        $opts{after}     || '',
        $opts{before}    || '',
        $opts{parent_id} || '',
        $opts{id}        || '',
        $opts{tags}      || '',
        $rows,
    );

    my $cond = {
        'cliente.status' => 'active',
        'me.escondido'   => 'false',
        'me.status'      => 'published',

        '-and' => [
            ($opts{id}     ? ({'me.id' => $opts{id}})              : ()),
            ($opts{after}  ? ({'me.id' => {'>' => $opts{after}}})  : ()),
            ($opts{before} ? ({'me.id' => {'<' => $opts{before}}}) : ()),
            (
                $opts{tags}
                ? (
                    # retorna qualquer tweets que contem aquele tema
                    {'-or' => [map { +{'me.tags_index' => {'like' => ",$_,"}} } split ',', $opts{tags}]}
                  )
                : ()
            ),
            (
                $opts{parent_id}
                ? ({parent_id => $opts{parent_id}})
                : (
                    $opts{id} ? ()            # nao remover comentarios se for um GET por ID
                    : {parent_id => undef}    # nao eh pra montar comentarios na timeline principal
                )
            ),
        ],
    };

    push $cond->{'-and'}->@*, {'me.cliente_id' => $ForceFilterClientes}  if $ForceFilterClientes;
    push $cond->{'-and'}->@*, {'me.cliente_id' => $user->{id}}           if $opts{only_myself};
    push $cond->{'-and'}->@*, {'me.cliente_id' => {'!=' => $user->{id}}} if $opts{skip_myself};

    delete $cond->{'-and'} if scalar $cond->{'-and'}->@* == 0;

    my $sort_direction = exists $opts{after} ? '-asc' : '-desc';
    my $attr           = {
        join       => 'cliente',
        order_by   => [{$sort_direction => 'me.id'}],
        rows       => $rows + 1,
        '+columns' => [
            {cliente_apelido            => 'cliente.apelido'},
            {cliente_modo_anonimo_ativo => 'cliente.modo_anonimo_ativo'},
            {cliente_avatar_url         => 'cliente.avatar_url'}
        ],
        result_class => 'DBIx::Class::ResultClass::HashRefInflator'
    };

    my @rows     = $c->schema2->resultset('Tweet')->search($cond, $attr)->all;
    my $has_more = scalar @rows > $rows ? 1 : 0;
    pop @rows if $has_more;

    my $remote_addr = $c->remote_addr;
    my @tweets;
    my @unique_ids;
    my @comments;
    foreach my $tweet (@rows) {

        push @unique_ids, $tweet->{id};
        push @unique_ids, $tweet->{ultimo_comentario_id}
          and push @comments, $tweet->{ultimo_comentario_id}
          if $tweet->{ultimo_comentario_id}
          && !$opts{parent_id}
          && !$opts{skip_comments};    # nao tem parent, faz 'prefetch' do ultmo comentarios

        my $item = &_fomart_tweet($user, $tweet, $remote_addr);

        push @tweets, $item;
    }

    my %last_reply;
    if (@comments) {

        # para fazer a pesquisa dos comentarios, nao importa a ordem, nem podemos limitar as linhas
        delete $attr->{rows};
        delete $attr->{order_by};
        my @childs = $c->schema2->resultset('Tweet')->search({'me.id' => {in => \@comments}}, $attr)->all;
        foreach my $me (@childs) {
            $last_reply{$me->{parent_id}} = &_fomart_tweet($user, $me, $remote_addr);
        }
    }

    my %already_liked = map { $_->{tweet_id} => 1 } $c->schema2->resultset('TweetLikes')->search(
        {cliente_id => $user->{id}, tweet_id => {'in' => \@unique_ids}},
        {
            columns      => ['tweet_id'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;

    foreach my $tweet (@tweets) {
        $tweet->{type} = 'tweet';
        $tweet->{meta}{liked} = $already_liked{$tweet->{id}} || 0;

        $tweet->{last_reply} = $last_reply{$tweet->{id}};
        if ($tweet->{last_reply}) {
            $tweet->{last_reply}{meta}{liked} = $already_liked{$tweet->{last_reply}->{id}} || 0;
        }
    }

    $c->add_tweets_highlights(user => $user, tweets => \@tweets);

    # nao adicionar noticias nos detalhes
    $c->add_tweets_news(user => $user, tweets => \@tweets, tags => $opts{tags})
      if !$opts{parent_id};

    return {
        tweets   => \@tweets,
        has_more => $has_more,
        order_by => $sort_direction eq '-desc' ? 'latest_first' : 'oldest_first',

        (
            $opts{parent_id}
            ? (
                parent => &_get_tweet_by_id($c, $user, $opts{parent_id}),
              )
            : ()
        ),
    };
}

sub _fomart_tweet {
    my ($user, $me, $remote_addr) = @_;
    my $avatar_anonimo = $ENV{AVATAR_ANONIMO_URL};
    my $avatar_default = $ENV{AVATAR_PADRAO_URL};

    my $anonimo = $me->{anonimo} || $me->{cliente_modo_anonimo_ativo};

    my $media_ref = [];

    if ($me->{media_ids} && $me->{media_ids} =~ /^\[/) {
        foreach my $media_id (@{from_json($me->{media_ids}) || []}) {
            push @$media_ref, {
                sd => &_gen_uniq_media_url($media_id, $user, 'sd', $remote_addr),
                hd => &_gen_uniq_media_url($media_id, $user, 'hd', $remote_addr),
            };
        }
    }

    return {
        meta => {
            owner => $user->{id} == $me->{cliente_id} ? 1 : 0,
        },
        id               => $me->{id},
        content          => $me->{disable_escape} ? $me->{content} : xml_escape($me->{content}),
        anonimo          => $anonimo ? 1 : 0,
        qtde_likes       => $me->{qtde_likes},
        qtde_comentarios => $me->{qtde_comentarios},
        media            => $media_ref,
        icon             => $anonimo ? $avatar_anonimo : $me->{cliente_avatar_url} || $avatar_default,
        name             => $anonimo ? 'Anônimo' : $me->{cliente_apelido},
        created_at       => $me->{created_at},
        _tags_index      => $me->{tags_index},
        ($anonimo ? () : (cliente_id => $me->{cliente_id})),

    };
}

sub _gen_uniq_media_url {
    my ($media_id, $user, $quality, $ip) = @_;

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . $user->{id} . $quality . $ip), 0, 12);
    return $ENV{PUBLIC_API_URL} . "media-download/?m=$media_id&q=$quality&h=$hash";
}

sub _get_tweet_by_id {
    my ($c, $user, $tweet_id) = @_;

    my $list  = &list_tweets($c, id => $tweet_id, user => $user, skip_comments => 1,);
    my $tweet = $list->{tweets}[0];
    $c->reply_item_not_found() unless $tweet;
    return $tweet;
}

sub _get_tracked_news_url {
    my ($user, $news) = @_;

    my $userid      = $user->{id};
    my $newsid      = $news->{id};
    my $url         = $news->{hyperlink};
    my $valid_until = time() + 3600;
    my $trackid     = random_string(4);

    my $hash = substr(md5_hex(join ':', $ENV{NEWS_HASH_SALT}, $userid, $newsid, $trackid, $valid_until, $url), 0, 12);
    return
        $ENV{PUBLIC_API_URL}
      . "news-redirect/?uid=$userid&nid=$newsid&u=$valid_until&t=$trackid&h=$hash&url="
      . url_escape($url);
}

sub add_tweets_highlights {
    my ($c, %opts) = @_;

    my $user   = $opts{user}   or croak 'missing user';
    my $tweets = $opts{tweets} or croak 'missing tweets';

    my $config = &kv()->redis_get_cached_or_execute(
        'tags_highlight_regexp',
        60 * 10,    # 10 minutes
        sub {
            my $rs       = $c->schema2->resultset('TagsHighlight');
            my $query_rs = $rs->search(
                {
                    'noticia.published' => 'published',
                    'me.status'         => is_test() ? 'test' : 'prod',
                    'me.error_msg'      => '',
                },
                {
                    join    => {'tag' => {'noticias2tags' => 'noticia'}},
                    columns => [
                        {
                            noticias => \ "CONCAT('[', group_concat(
                                JSON_OBJECT(
                                    'id',noticia.id,
                                    'title', noticia.title,
                                    'hyperlink', noticia.hyperlink
                                ) ORDER BY noticia.display_created_time DESC SEPARATOR ',' LIMIT 15
                            ), ']')"
                        },
                        (qw/me.id me.is_regexp me.tag_id me.match/),
                    ],
                    group_by     => 'me.id',
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            );

            my @highlights;
            my @regexps;
            while (my $row = $query_rs->next()) {

                my $match = $row->{match};
                if ($row->{is_regexp}) {

                    my $test = eval {
                        die "não pode ter parenteses sem escape\n" if $match =~ /[^\\]\(/;
                        qr/$match/i;
                    };
                    if ($@) {
                        $rs->find($row->{id})->update({error_msg => "Regexp error: $@"});
                        next;
                    }
                }
                else {
                    my $new_regex = '(' . join('|', (map { quotemeta(trim($_)) } split qr{\|}, $match)) . ')';

                    # evita regexp que da match pra tudo
                    $new_regex =~ s{\|\|}{|}g;    # troca || por só |
                    $new_regex =~ s{\|\)}{)};     # troca |) por só )
                    $new_regex =~ s{\(\|}{(};     # troca (| pro só (

                    $match = $new_regex;
                }

                push @regexps, $match;

                push @highlights, {
                    regexp   => $match,
                    noticias => from_json($row->{noticias}),
                    id       => $row->{id},
                    tag_id   => $row->{tag_id},
                };
            }

            return {
                highlights => \@highlights,
                test       => scalar @regexps ? '\\b(' . join('|', @regexps) . ')\\b' : undef,
            };
        }
    );

    # se nao tem nada, nao precisa fazer loop algum.
    return 1 unless $config->{test};

    my $prefix  = ('<span style="color: #f982b4">');
    my $postfix = ('</span>');

    foreach my $tweet (@$tweets) {
        my $current_tags = delete $tweet->{_tags_index};

        # se nao da match em nenhuma tag atualmente, e nao tem tag, nao precisa atualizar, nem passar no loop
        next if $tweet->{content} !~ m/$config->{test}/i && ($current_tags eq ',,' || !defined $current_tags);

        my %seen_tags;
        my $content = $tweet->{content};
        $tweet->{related_news} = [];
        foreach my $highlight (@{$config->{highlights}}) {
            my $regexp = $highlight->{regexp};
            if ($content =~ s/\b($regexp)\b/$prefix$1$postfix/gi) {
                my $news = sample(1, @{$highlight->{noticias}});

                $seen_tags{$highlight->{tag_id}}++;
                push @{$tweet->{related_news}}, {
                    hyperlink => &_get_tracked_news_url($user, $news),
                    title     => $news->{title},
                };
            }
        }
        $tweet->{content} = $content;

        # atualiza de forma lazy os tweets com as tags que dão match atualmente
        my $new_tweet_tags = ',' . (join ',', sort keys %seen_tags) . ',';
        if ($current_tags && $current_tags ne $new_tweet_tags) {
            $c->schema2->resultset('Tweet')->search({id => $tweet->{id}})->update({tags_index => $new_tweet_tags});
        }
    }

    return 1;
}

sub add_tweets_news {
    my ($c, %opts) = @_;

=pod
    my @tweets2;
    my $i = 0;
    foreach my $tweet (@tweets) {
        push @tweets2, $tweet;
        if (++$i % 3 == 0 && $include_news) {

            my $news = $c->schema2->resultset('Noticia')
              ->search({published => 'published'}, {rows => 1, offset => int(rand() * 99)})->next;
            if ($news) {
                push @tweets2, {
                    type     => 'news',
                    href     => $news->hyperlink,
                    title    => $news->title,
                    source   => $news->fonte,
                    date_str => $news->display_created_time->dmy('/'),
                    image =>
                      'https://s2.glbimg.com/IKEfOHvbA827tcq660lssE-11mI=/512x320/smart/e.glbimg.com/og/ed/f/original/2020/06/19/82145061_2427549444202692_6151441996146155645_n.jpg',
                };
            }
        }
        elsif (++$i % 10 == 0 && $include_news) {

            my @news = $c->schema2->resultset('Noticia')
              ->search({published => 'published'}, {rows => 4, offset => int(rand() * 99)})->all;
            if (scalar @news) {
                push @tweets2, {
                    type   => 'news_group',
                    header => 'Relacionamento API Random',
                    news   => [
                        map {
                            +{
                                href     => $_->hyperlink,
                                title    => $_->title,
                                source   => $_->fonte,
                                date_str => $_->display_created_time->dmy('/'),
                                image =>
                                  'https://s2.glbimg.com/IKEfOHvbA827tcq660lssE-11mI=/512x320/smart/e.glbimg.com/og/ed/f/original/2020/06/19/82145061_2427549444202692_6151441996146155645_n.jpg',
                            }
                        } @news,
                    ],
                };
            }
        }
    }
=cut

}

1;
