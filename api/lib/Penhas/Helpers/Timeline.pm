package Penhas::Helpers::Timeline;
use common::sense;
use Carp qw/confess /;
use utf8;
use Penhas::KeyValueStorage;
use Scope::OnExit;
use Digest::MD5 qw/md5_hex/;
use Mojo::Util qw/trim xml_escape url_escape dumper/;
use List::Util;

use JSON;
use Penhas::Logger;
use Penhas::Utils;
use List::Util '1.54' => qw/sample/;
use DateTime::Format::Pg;
use Encode;

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

    my $user   = $opts{user} or confess 'missing user';
    my $id     = $opts{id}   or confess 'missing id';
    my $remove = $opts{remove};

    confess 'missing remove' unless defined $remove;

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

    my $liked;
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
        $liked++;
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

    if ($liked && notifications_enabled()) {
        my $anonimo    = $user->{modo_anonimo_ativo} ? 1 : 0;
        my $subject_id = $anonimo                    ? 0 : $user->{id};
        my $job_id     = $c->minion->enqueue(
            'new_notification',
            [
                'new_like',
                {tweet_id => $reference->id, subject_id => $subject_id}
            ] => {
                attempts => 5,
            }
        );
        $ENV{LAST_NTF_LIKE_JOB_ID} = $job_id;
    }

    return {tweet => &_get_tweet_by_id($c, $user, $reference->id)};
}

sub delete_tweet {
    my ($c, %opts) = @_;

    my $user = $opts{user} or confess 'missing user';
    my $id   = $opts{id}   or confess 'missing id';

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

    my $user      = $opts{user}     or confess 'missing user';
    my $user_obj  = $opts{user_obj} or confess 'missing user_obj';
    my $content   = $opts{content}  or confess 'missing content';
    my $media_ids = $opts{media_ids};
    my $reply_to  = $opts{reply_to};

    my $post_as_admin = $user_obj->eh_admin && $c->user_preference_is_active($user_obj->id, 'POST_AS_PENHAS') ? 1 : 0;

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

    # die {message => 'O conteÃºdo precisa ser menor que 500 caracteres', error => 'tweet_too_long'}
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

    # permite atÃ© 9999 tweets em 1 segundo, acho que ta ok pra este app!
    # se tiver tudo isso de tweet em um segundo, aguarda o proximo segundo!
    if ($cur_seq == 9999) {
        sleep 1;
        goto AGAIN;
    }
    my $id = $base . sprintf('%04d', $cur_seq);
    my $rs = $c->schema2->resultset('Tweet');

    my $depth              = 1;
    my $original_parent_id = $reply_to;

    my $root_tweet_id;
    if ($original_parent_id && $ENV{SUBSUBCOMENT_DISABLED}) {

        # procura o tweet raiz [e conta o depth]
        while (1) {
            my $parent = $rs->search({id => $reply_to}, {columns => ['id', 'parent_id']})->next;
            last                           if !$parent;
            $reply_to = $parent->parent_id if $parent->parent_id;
            $depth++;

            last if !$parent->parent_id;
            last if $parent->parent_id eq $parent->id;    # just in case
        }

        # pra nao bugar o app se rodar com SUBSUBCOMENT_DISABLED=1
        $root_tweet_id = $reply_to;
    }
    elsif ($original_parent_id) {
        my $tmp_parent_id = $reply_to;

        # procura o tweet raiz para contar o depth
        while (1) {
            my $parent = $rs->search({id => $tmp_parent_id}, {columns => ['id', 'parent_id']})->next;
            last                                if !$parent;
            $tmp_parent_id = $parent->parent_id if $parent->parent_id;
            $depth++;
            last if !$parent->parent_id;
            last if $parent->parent_id eq $parent->id;    # just in case
        }
        $root_tweet_id = $tmp_parent_id;
    }

    my $anonimo = $user->{modo_anonimo_ativo} ? 1 : 0;
    my $tweet   = $rs->create(
        {
            status             => 'published',
            id                 => $id,
            content            => $content,
            cliente_id         => $user->{id},
            anonimo            => $anonimo,
            parent_id          => $reply_to,
            created_at         => $now->datetime(' '),
            media_ids          => $media_ids ? to_json($media_ids) : undef,
            original_parent_id => $original_parent_id,
            tweet_depth        => $depth,
            use_penhas_avatar  => $post_as_admin,
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

        if (notifications_enabled()) {
            my $subject_id = $anonimo ? 0 : $user->{id};
            my $job_id     = $c->minion->enqueue(
                'new_notification',
                [
                    'new_comment',
                    {
                        tweet_id      => $original_parent_id,
                        comment_id    => $tweet->id,
                        subject_id    => $subject_id,
                        comment       => $content,
                        root_tweet_id => $root_tweet_id,
                    }
                ] => {
                    attempts => 5,
                }
            );
            $ENV{LAST_NTF_COMMENT_JOB_ID} = $job_id;
        }
    }

    return &_get_tweet_by_id($c, $user, $tweet->id);
}


sub report_tweet {
    my ($c, %opts) = @_;

    my $user        = $opts{user}   or confess 'missing user';
    my $reason      = $opts{reason} or confess 'missing reason';
    my $reported_id = $opts{id}     or confess 'missing id';

    slog_info(
        'report_tweet reported_id=%s, reason=%s',
        $reported_id, $reason,
    );

    my $lock = "tweet_id:$reported_id";
    kv->lock_and_wait($lock);
    on_scope_exit { kv->unlock($lock) };

    my $report = $c->schema2->resultset('TweetsReport')->create(
        {
            reason      => $reason,
            cliente_id  => $user->{id},
            reported_id => $reported_id,
            created_at  => DateTime->now->datetime(' '),
        }
    );
    die 'id missing' unless $report->id;

    $c->schema2->resultset('Tweet')->search(
        {
            'id' => $reported_id,
        }
    )->update({qtde_reportado => \'qtde_reportado + 1'});


    if ($ENV{EMAIL_TWEET_REPORTADO}) {
        my $tweet = $c->schema2->resultset('Tweet')->find($reported_id);
        $c->schema->resultset('EmaildbQueue')->create(
            {
                config_id => 1,
                template  => 'tweet_reportado.html',
                to        => $ENV{EMAIL_TWEET_REPORTADO},
                subject   => 'PenhaS - Tweet reportado - Qtde reports ' . $tweet->qtde_reportado,
                variables => to_json(
                    {
                        tweet => {
                            id             => $tweet->id,
                            content        => $tweet->content,
                            qtde_reportado => $tweet->qtde_reportado
                        },
                        report => {
                            id     => $report->id,
                            reason => $reason,
                        }
                    }
                ),
            }
        );
    }

    return {id => $report->id};
}

sub list_tweets {
    my ($c, %opts) = @_;

    my $rows = $opts{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $user      = $opts{user} or confess 'missing user';
    my $user_obj  = $opts{skip_comments} ? undef : ($opts{user_obj} or confess 'missing user_obj');
    my $is_legacy = $opts{is_legacy};
    my $os        = $opts{os};

    my $blocked_users = [];

    my $modules_str = $user_obj ? $user_obj->access_modules_str : ',tweets,';
    my $category    = $opts{category} || 'all';
    if ($user_obj) {

        $blocked_users = $user_obj->timeline_clientes_bloqueados_ids;

        # se pediu por tudo que pode incluir tweets, mas nao eh tem permissao pros tweets,
        # volta dar erro
        if ($category =~ /^(all_myself|only_tweets)$/ && $modules_str !~ /,tweets,/) {
            $c->reply_invalid_param('sua conta não tem permissão para utilizar esse filtro.');
        }
    }

    # se for "tudo", mas nao ter tweets, vamos remover e deixar only_news
    if ($category eq 'all' && $modules_str !~ /,tweets,/) {
        log_info("changing category form '$category' to only_news");
        $category = 'all_but_news';
    }

    $opts{$_} ||= '' for qw/after before parent_id id tags/;

    # nao pode ter nenhuma busca por algo especifico
    my $is_first_page = !$opts{parent_id} & !$opts{after} & !$opts{before} & !$opts{id};

    if ($opts{next_page}) {
        $is_first_page = 0;

        slog_info('list_tweets applying next_page=%s', to_json($opts{next_page}));

        $c->reply_invalid_param('uso do parent_id com next_page é vedado') if $opts{parent_id};
        $c->reply_invalid_param('uso do after com next_page é vedado')     if $opts{after};
        $c->reply_invalid_param('uso do before com next_page é vedado')    if $opts{before};
        $c->reply_invalid_param('uso do id com next_page é vedado')        if $opts{id};

        $opts{before} = $opts{next_page}{before};

        if ($opts{tags} ne $opts{next_page}{tags}) {
            $c->reply_invalid_param('não pode trocar de tags durante uso do next_page');
        }
    }

    slog_info(
        'list_tweets category=%s after=%s before=%s parent_id=%s id=%s tags=%s rows=%s',
        $category        || '-',
        $opts{after}     || '-',
        $opts{before}    || '-',
        $opts{parent_id} || '-',
        $opts{id}        || '-',
        $opts{tags}      || '-',
        $rows            || '-',
    );

    my $cond = {
        'cliente.status' => 'active',
        'me.status'      => 'published',

        '-and' => [
            ($opts{id}     ? ({'me.id' => $opts{id}})              : ()),
            ($opts{after}  ? ({'me.id' => {'>' => $opts{after}}})  : ()),
            ($opts{before} ? ({'me.id' => {'<' => $opts{before}}}) : ()),
            (
                $opts{tags}
                ? (
                    # retorna qualquer tweets que contem aquele tema
                    {'-or' => [map { +{'me.tags_index' => {'like' => "%,$_,%"}} } split ',', $opts{tags}]}
                  )
                : ()
            ),
            (
                $opts{parent_id}
                ? ({parent_id => $opts{parent_id}})
                : (
                    $opts{id} || $category eq 'all_myself'
                    ? ()                    # nao remover comentarios se for um GET por ID, ou listar tudo de um usaurio
                    : {parent_id => undef}  # nao eh pra montar comentarios na timeline principal
                )
            ),

            (
                @$blocked_users > 0
                ? (
                    {
                        '-or' => [
                            {'me.anonimo'    => 'true'},
                            {'me.cliente_id' => {'not in' => $blocked_users}},
                        ]
                    }
                  )
                : ()
            ),
        ],
    };

    push $cond->{'-and'}->@*, {'me.cliente_id' => $ForceFilterClientes} if $ForceFilterClientes;
    if ($category eq 'all_myself') {
        push $cond->{'-and'}->@*, {'me.cliente_id' => $user->{id}};
    }
    elsif ($category eq 'only_news' || $category eq 'all_but_news') {

        # filtra por um id que nao existe
        push $cond->{'-and'}->@*, \'0 = 1';
    }

    delete $cond->{'-and'} if scalar $cond->{'-and'}->@* == 0;

    my $sort_direction = $opts{after} ? '-asc' : '-desc';
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

    my $rs       = $c->schema2->resultset('Tweet')->search($cond, $attr);
    my $is_admin = $user_obj ? $user_obj->eh_admin : 0;
    if (!$is_admin) {
        $rs = $rs->search(
            {
                '-and' => [
                    {
                        '-or' => [
                            {'me.escondido' => 'false'},
                            (
                                $user_obj
                                ? (
                                    {'me.cliente_id' => $user_obj->id},
                                  )
                                : ()
                            )
                        ]
                    }
                ]
            }
        );
    }

    #log_info(dumper([$cond, $attr]));
    my @rows     = $rs->all;
    my $has_more = scalar @rows > $rows ? 1 : 0;

#    log_info(dumper([@rows]));

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

        my $item = &_format_tweet($user, $tweet, $remote_addr);

        push @tweets, $item;
    }

    # carrega o last_tweet antes de mudar a lista pra adicionar os outros tipos
    my $last_tweet = scalar @tweets ? $tweets[-1]{id} : undef;

    my %last_reply;
    if (@comments) {

        # para fazer a pesquisa dos comentarios, nao importa a ordem, nem podemos limitar as linhas
        delete $attr->{rows};
        delete $attr->{order_by};
        my @childs = $c->schema2->resultset('Tweet')->search(
            {
                'me.id'          => {in => \@comments},
                'me.status'      => 'published',
                'me.escondido'   => 'false',
                'cliente.status' => 'active',

                (
                    @$blocked_users > 0
                    ? (
                        '-or' => [
                            {'me.anonimo'    => 'true'},
                            {'me.cliente_id' => {'not in' => $blocked_users}},
                        ]
                      )
                    : ()
                ),
            },
            $attr
        )->all;
        foreach my $me (@childs) {
            $last_reply{$me->{parent_id}} = &_format_tweet($user, $me, $remote_addr);
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

    my $next_page;

    # nao adicionar noticias nos detalhes
    # nem quando sao tweets puxados com after
    # tambem nao deve ter next_page
    if (!$opts{parent_id} && !$opts{after} && !$opts{id}) {

        $next_page = {
            tags   => $opts{tags},
            before => $last_tweet ? $last_tweet : '000000T0000000000',
            iss    => 'next_page',
        };

        if ($category =~ /^(all|only_news|all_but_news)$/) {
            $c->add_tweets_news(
                user     => $user,
                tweets   => \@tweets,
                category => $category,
                tags     => $opts{tags},
                %{$opts{next_page}},
                next_page => $next_page,
            );

            $has_more = 1 if delete $next_page->{set_has_more_true};
        }

        #log_info('next page . ' . dumper($next_page));

        $next_page = $c->encode_jwt($next_page, 1);
    }

    # restaura pra 'all'
    $category = 'all' if $category eq 'all_but_news';

    #log_info('$category . ' . $$category);
    #log_info('tweets . ' . dumper(\@tweets));

    if ($is_first_page && $is_legacy && $tweets[0] && $tweets[0]{type} eq 'tweet') {
        unshift @tweets, _add_legacy_tweet($user_obj, $tweets[0]{id}, $os);
    }


    return {
        tweets   => \@tweets,
        has_more => $has_more,
        order_by => $sort_direction eq '-desc' ? 'latest_first' : 'oldest_first',
        category => $category,
        ($next_page ? (next_page => $next_page) : ()),

        (
            $opts{parent_id}
            ? (
                parent => &_get_tweet_by_id($c, $user, $opts{parent_id}),
              )
            : ()
        ),
    };
}


sub _add_legacy_tweet {
    my ($user_obj, $tweet_id, $os) = @_;
    my $avatar_penhas = $ENV{AVATAR_PENHAS_URL};

    my $apelido = $user_obj->apelido;
    my $logos   = {
        Android => 'https://azmina.com.br/wp-content/uploads/2019/02/Logo_Google.png',
        iOS     => 'https://azmina.com.br/wp-content/uploads/2019/02/Logo_Apple.png'
    };
    my $links = {
        Android => 'https://play.google.com/store/apps/details?id=penhas.com.br',
        iOS     => 'https://apps.apple.com/br/app/penhas/id1441569466'
    };
    my $img  = $logos->{$os};
    my $link = $links->{$os};

    return {
        type       => 'tweet',
        id         => $tweet_id,
        created_at => '2099-01-01T01:01:01',
        meta       => {
            liked     => 0,
            owner     => 0,
            can_reply => 0,
            parent_id => undef,
        },

        content => qq|Olá, $apelido.<br>
<br>
Recentemente lançamos uma nova ferramenta aqui no PenhaS chamada Manual de Fuga. Além disso, também melhoramos a navegação em nossas páginas. Para ter acesso às melhorias é importante que você atualize o app diretamente na sua loja - Play Store ou Apple Store.<br>
<br>
Um forte abraço!<br>
<br>
<div style="text-align:center">
<a href="$link">
    <img width="300" height="93" src="$img">
</a>
</div>
|,
        qtde_likes       => 0,
        qtde_comentarios => 0,
        media            => [],
        icon             => $avatar_penhas,
        cliente_id       => 0,
        anonimo          => 1,
        name             => 'Atualização está disponível!',

    };
}


sub _format_tweet {
    my ($user, $me, $remote_addr) = @_;
    my $avatar_anonimo = $ENV{AVATAR_ANONIMO_URL};
    my $avatar_default = $ENV{AVATAR_PADRAO_URL};
    my $avatar_penhas  = $ENV{AVATAR_PENHAS_URL};

    my $penhas_avatar = $me->{use_penhas_avatar};
    my $anonimo       = $me->{anonimo} || $me->{cliente_modo_anonimo_ativo};

    my $eh_admin = defined $user && $user->{eh_admin};

    my $media_ref = [];

    if ($me->{media_ids} && $me->{media_ids} =~ /^\[/) {
        foreach my $media_id (@{from_json($me->{media_ids}) || []}) {
            push @$media_ref, {
                sd => &_gen_uniq_media_url($media_id, $user, 'sd', $remote_addr),
                hd => &_gen_uniq_media_url($media_id, $user, 'hd', $remote_addr),
            };
        }
    }

    my $is_owner = $user->{id} == $me->{cliente_id} ? 1 : 0;
    return {
        meta => {
            owner     => $is_owner,
            can_reply => $me->{tweet_depth} < 3 && $me->{tweet_depth} > 0 ? 1 : 0,

            parent_id => $me->{parent_id},
            (is_test() ? (tweet_depth_test_only => $me->{tweet_depth}) : ())
        },

        id      => $me->{id},
        content => $me->{disable_escape}
        ? $me->{content}
        : &maybe_linkfy(
            &nl2br(xml_escape($is_owner ? $me->{content} : &remove_pi($me->{content}))), $eh_admin, $is_owner
        ),
        anonimo => $anonimo && !$eh_admin ? 1 : 0,


        qtde_likes       => $me->{qtde_likes},
        qtde_comentarios => $me->{qtde_comentarios},
        media            => $media_ref,
        icon             => $anonimo ? $avatar_anonimo : $me->{cliente_avatar_url} || $avatar_default,
        name             => (
            $anonimo
            ? ($eh_admin ? $me->{cliente_apelido} . ' (Anônimo) ID ' . $me->{cliente_id} : 'Anônimo')
            : $me->{cliente_apelido}
        ),
        created_at  => pg_timestamp2iso_8601_second($me->{created_at}),
        _tags_index => $me->{tags_index},
        ($anonimo && !$eh_admin ? (cliente_id => 0) : (cliente_id => $me->{cliente_id})),
        (
            $penhas_avatar
            ? (
                cliente_id => 0,
                anonimo    => 1,
                icon       => $avatar_penhas,
                name       => 'Admin PenhaS',
              )
            : ()
        ),
    };
}

sub maybe_linkfy {
    my ($html, $eh_admin, $eh_dono) = @_;
    return &linkfy($html) if $eh_admin || $eh_dono;
    return $html;
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

    my $userid      = $user->{id}        or confess 'missing user.id';
    my $newsid      = $news->{id}        or confess 'missing news.id';
    my $url         = $news->{hyperlink} or confess 'missing news.hyperlink';
    my $valid_until = time() + 3600;
    my $trackid     = random_string(4);

    my $hash = substr(md5_hex(join ':', $ENV{NEWS_HASH_SALT}, $userid, $newsid, $trackid, $valid_until, $url), 0, 12);
    return
        $ENV{PUBLIC_API_URL}
      . "news-redirect/?uid=$userid&nid=$newsid&u=$valid_until&t=$trackid&h=$hash&url="
      . url_escape(encode_utf8($url));
}

sub _get_proxy_image_url {
    my ($url) = @_;

    my $hash = substr(md5_hex($ENV{MEDIA_HASH_SALT} . encode_utf8($url)), 0, 12);

    return $ENV{PUBLIC_API_URL} . "get-proxy/?h=$hash&href=" . url_escape(encode_utf8($url));
}

sub add_tweets_highlights {
    my ($c, %opts) = @_;

    my $user   = $opts{user}   or confess 'missing user';
    my $tweets = $opts{tweets} or confess 'missing tweets';

    my $config = &kv()->redis_get_cached_or_execute(
        'tags_highlight_regexp',
        60 * 10,    # 10 minutes
        sub {
            my $rs       = $c->schema2->resultset('TagsHighlight');
            my $query_rs = $rs->search(
                {
                    'me.status'    => is_test() ? 'test' : 'prod',
                    'me.error_msg' => '',
                },
                {
                    # join    => {'tag' => {'noticias_tags' => 'noticia'}},
                    join    => 'tag',
                    columns => [
                        {
                            noticias => \[
                                "(select json_agg(sub) from (
                                            select
                                                noticia.id,
                                                noticia.title,
                                                noticia.hyperlink,
                                                noticia.fonte as source
                                            FROM noticias noticia
                                            JOIN noticias_tags n2t ON n2t.noticias_id = noticia.id
                                                                  AND n2t.tags_id     = me.tag_id
                                            WHERE noticia.published = ?
                                            ORDER BY noticia.created_at DESC
                                            LIMIT 15
                                ) sub
                            )", is_test() ? 'published:testing' : 'published'
                            ]
                        },
                        (qw/me.id me.is_regexp me.tag_id me.match /),
                        {header => 'tag.title'}
                    ],
                    group_by     => ['me.id', 'tag.title'],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            );

            my @highlights;
            my @regexps;
            while (my $row = $query_rs->next()) {

                my $match = $row->{match};
                if ($row->{is_regexp}) {

                    my $test = eval {qr/$match/i};
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

                next unless $row->{noticias};
                push @regexps,    $match;
                push @highlights, {
                    regexp   => $match,
                    noticias => from_json($row->{noticias}),
                    id       => $row->{id},
                    tag_id   => $row->{tag_id},
                    header   => $row->{header},
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

    my @list = splice $tweets->@*, 0;

    foreach my $tweet (@list) {
        push $tweets->@*, $tweet;
        my $current_tags = delete $tweet->{_tags_index};

        # se nao da match em nenhuma tag atualmente, e nao tem tag, nao precisa atualizar, nem passar no loop
        next if $tweet->{content} !~ m/$config->{test}/i && ($current_tags eq ',,' || !defined $current_tags);

        my %seen_tags;
        my $content = $tweet->{content};

        my @headers;
        my $seen_headers;
        my @related_news;

        foreach my $highlight (@{$config->{highlights}}) {
            my $regexp = $highlight->{regexp};
            if ($content =~ s/\b($regexp)\b/$prefix$1$postfix/gi) {

                my $news = sample(1, @{$highlight->{noticias}});

                $seen_tags{$highlight->{tag_id}}++;
                push @related_news, {
                    href   => &_get_tracked_news_url($user, $news),
                    title  => $news->{title},
                    source => $news->{source},
                };

                if (!$seen_headers->{$highlight->{header}}) {
                    $seen_headers->{$highlight->{header}}++;

                    push @headers, $highlight->{header};
                }
            }
        }
        $tweet->{content} = $content;

        my $header = '';
        if (@related_news) {
            my $last = pop @headers;

            $header = (join ', ', @headers) . (@headers ? ' e ' . $last : $last);

            push $tweets->@*, {
                type   => 'related_news',
                news   => \@related_news,
                header => $header,
            };
        }

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

    log_info("running add_tweets_news");

    my $tags       = $opts{tags};
    my $plain_news = $tags ? 1 : $opts{category} eq 'only_news';
    my $news_added = {map { $_ => 1 } @{$opts{news_added} || []}};

    # esvazia os itens da array, mas mantem a referencia
    my @list = splice $opts{tweets}->@*, 0;

    my (@vitrine, @news);
    if ($plain_news) {
        my $expected_rows = int(scalar @list / 3);
        $expected_rows = 3 if $expected_rows < 3;

        log_info("asking for $expected_rows rows of Noticias");
        log_info("\$news_added is " . dumper($news_added));

        my $cond = {
            'me.published' => is_test() ? 'published:testing' : 'published',
            'me.id'        => {'not in' => [keys %$news_added]},
            (
                $tags
                ? (
                    '-and' => [{'-or' => [map { +{'me.tags_index' => {'like' => "%,$_,%"}} } split ',', $tags]}],
                  )
                : (
                    'me.has_topic_tags' => '1',
                )
            ),
        };

        @news = $c->schema2->resultset('Noticia')->search(
            $cond,
            {
                order_by     => [{'-desc' => 'me.display_created_time'}],
                rows         => $expected_rows + 1,
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            }
        )->all;

        my $has_more = scalar @news > $expected_rows ? 1 : 0;
        pop @news if $has_more;

        $opts{next_page}{set_has_more_true} = $has_more;

        #log_info("news array . " . dumper(\@news));
    }
    else {
        my $expected_rows = int(scalar @list / 3);
        $expected_rows = 3 if $expected_rows < 3;

        log_info("asking for $expected_rows rows of NoticiasVitrine");

        my $last_vitrine_order = $opts{vitrine_order} || -1;

        log_info("vitrine last_vitrine_order= $last_vitrine_order");
        @vitrine = $c->schema2->resultset('NoticiasVitrine')->search(
            {
                status => is_test() ? 'test' : 'prod',
                order  => {'>' => $last_vitrine_order},
            },
            {
                order_by     => 'me.order',
                rows         => $expected_rows + 1,
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        )->all;

        my $has_more = scalar @vitrine > $expected_rows ? 1 : 0;
        pop @vitrine if $has_more;

        $last_vitrine_order = $vitrine[-1]{order} if $vitrine[-1];

        $opts{next_page}{set_has_more_true} = $has_more;
        $opts{next_page}{vitrine_order}     = $last_vitrine_order;


        #log_info("vitrine array . " . dumper(\@vitrine));
    }


    my $news_conter = 0;
    my $idx         = 0;
    foreach my $tweet (@list) {
        push $opts{tweets}->@*, $tweet;

        $idx++;
        my $next_item = $list[$idx];
        next if $next_item && $next_item->{type} ne 'tweet';

        $news_conter++;

        next unless $news_conter % 3 == 0;


        if ($plain_news) {

            my $news = shift(@news);
            if ($news) {
                $news_added->{$news->{id}}++;
                push $opts{tweets}->@*, {
                    type   => 'news_group',
                    header => undef,
                    news   => [&_format_noticia($news, %opts)]
                };
            }

        }
        else {
            log_info("adicionando item de vitrine");
          AGAIN:
            my $vitrine = shift(@vitrine);

            if ($vitrine) {
                $vitrine = &_process_vitrine_item(
                    $vitrine,
                    $news_added,
                    user => $opts{user}
                );

                # pega mais uma item, caso nao tenha nada (todas noticias ja foram entregues)
                goto AGAIN unless $vitrine;

                log_info("=> " . dumper($vitrine));

                push $opts{tweets}->@*, $vitrine;
            }
        }


    }

    # sobrou itens, nao tinha tweets suficientes para preencher tudo
    if (@vitrine && !$ENV{SKIP_END_NEWS}) {
        log_info("alguns itens da vitrine ainda existem... adicionando no final");
        foreach my $item (@vitrine) {
            my $vitrine = &_process_vitrine_item(
                $item,
                $news_added,
                user => $opts{user}
            );

            push $opts{tweets}->@*, $vitrine if $vitrine;
        }
    }

    # sobrou itens, nao tinha tweets suficientes para preencher tudo
    if (@news && !$ENV{SKIP_END_NEWS}) {
        log_info("alguns itens da noticias ainda existem... adicionando no final");
        foreach my $r (@news) {
            $news_added->{$r->{id}}++;
            push $opts{tweets}->@*, {
                type   => 'news_group',
                header => undef,
                news   => [&_format_noticia($r, %opts)]
            };
        }
    }

    log_info(dumper($news_added));

    $opts{next_page}{news_added} = [keys %$news_added];

    # descobre todas as noticias que precisam ser carregas e marca qual em objeto
    my $news_item_ref;
    my @group_news_ids;

    if (!$plain_news) {
        foreach my $item ($opts{tweets}->@*) {
            next unless $item->{type} eq 'news_group';

            foreach my $new_id ($item->{news}->@*) {
                push @group_news_ids, $new_id;
                push @{$news_item_ref->{$new_id}}, $item;
            }
        }
    }

    if (@group_news_ids) {

        # carrega as noticias
        my $news_rs = $c->schema2->resultset('Noticia')->search(
            {
                #published => is_test() ? 'published:testing' : 'published',
                id => {'in' => \@group_news_ids}
            },
            {
                columns      => [qw/me.id me.title me.display_created_time me.fonte me.hyperlink me.image_hyperlink/],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator'
            }
        );
        my $x = 0;
        while (my $r = $news_rs->next) {
            $x++;
            my $new_rendered = &_format_noticia($r, %opts);
            delete $new_rendered->{type};

            # atualiza todas as referencias
            foreach my $item ($news_item_ref->{$r->{id}}->@*) {
                $item->{_news}{$r->{id}} = $new_rendered;
            }
        }
        die 'not matched' if $x != scalar @group_news_ids && is_test();

        # percorre novamente a lista, colocando as noticias na ordem que apareceram
        foreach my $item ($opts{tweets}->@*) {
            next unless $item->{type} eq 'news_group';

            my @news_in_order;
            foreach my $new_id ($item->{news}->@*) {
                push @news_in_order, $item->{_news}{$new_id} if $item->{_news}{$new_id};
            }

            $item->{news} = \@news_in_order;

            delete $item->{_news};
        }
    }

}

sub _format_noticia {
    my ($r, %opts) = @_;

    $opts{user} or confess 'missing $opts{user}';

    return {
        #type     => 'news',
        id       => $r->{id},
        href     => &_get_tracked_news_url($opts{user}, $r),
        title    => $r->{title},
        source   => $r->{fonte},
        date_str => DateTime::Format::Pg->parse_datetime($r->{display_created_time})->dmy('/'),
        image    => (
              $r->{image_hyperlink}
            ? &_get_proxy_image_url($r->{image_hyperlink})
            : $ENV{NEWS_DEFAULT_IMAGE} || $ENV{PUBLIC_API_URL} . '/avatar/news.jpg'
        )
    };
}

sub _process_vitrine_item {
    my ($vitrine, $news_added, %opts) = @_;

    my $noticias = from_json($vitrine->{noticias});
    die "vitrine.noticias is not array on " . $vitrine->{id} unless ref $noticias eq 'ARRAY';

    my $meta = from_json($vitrine->{meta});
    die "vitrine.meta is not hash on " . $vitrine->{id} unless ref $meta eq 'HASH';

    my $news_group;
    my @out_news;

    for my $news_id (@$noticias) {
        next if $news_added->{$news_id};

        push @out_news, $news_id;

        $news_added->{$news_id}++;
    }

    if (@out_news) {
        $news_group = {
            type   => 'news_group',
            header => $meta->{title},
            news   => \@out_news
        };
    }

    return $news_group;
}


1;
