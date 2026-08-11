use Mojo::Base -strict;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Test2::V0;

use Penhas::Helpers::Timeline;
use Penhas::Utils qw/looks_like_html tweet_content_is_html/;

{
    package FakeUser;
    sub new        { my ($class, %o) = @_; return bless \%o, $class }
    sub eh_admin   { $_[0]{eh_admin} || 0 }
    sub id         { $_[0]{id} }
    sub cep_cidade { $_[0]{cep_cidade} || '' }
    sub check_location_badge_for_cidade { return () }
}

{
    package FakeKV;
    sub new { my ($class, $config) = @_; return bless {config => $config}, $class }
    sub redis_get_cached_or_execute { my ($self, $key, $ttl, $sub) = @_; return $self->{config} }
}

sub _mk_user {
    my (%o) = @_;
    $o{id} //= 1;
    return FakeUser->new(%o);
}

sub _mk_row {
    my (%o) = @_;
    return {
        use_penhas_avatar        => $o{penhas}         ? 1 : 0,
        disable_escape           => $o{disable_escape} ? 1 : 0,
        anonimo                  => 0,
        cliente_modo_anonimo_ativo => 0,
        content                  => $o{content} // '',
        media_ids                => undef,
        cliente_id               => $o{author_id} // 2,
        tweet_depth              => 1,
        parent_id                => undef,
        badges                   => [],
        created_at               => '2024-01-01 00:00:00',
        tags_index               => ',,',
        cliente_apelido          => $o{apelido} // 'Fulana',
        cliente_avatar_url       => undef,
        cliente_cep_cidade       => undef,
        qtde_likes               => 0,
        qtde_comentarios         => 0,
    };
}

sub _format {
    my ($user, $row) = @_;
    return Penhas::Helpers::Timeline::_format_tweet($user, $row, '127.0.0.1');
}

subtest 'tweet_content_is_html decide o roteamento' => sub {
    is(tweet_content_is_html(disable_escape => 1, use_penhas_avatar => 0, content => 'texto puro'), 1,
        'disable_escape=true sempre vai para o caminho HTML');

    is(tweet_content_is_html(disable_escape => 0, use_penhas_avatar => 1, content => '<a href="https://x">y</a>'), 1,
        'admin com <a> vai para o caminho HTML');
    is(tweet_content_is_html(disable_escape => 0, use_penhas_avatar => 1, content => '<img src="https://x">'), 1,
        'admin com <img> vai para o caminho HTML');
    is(tweet_content_is_html(disable_escape => 0, use_penhas_avatar => 1, content => 'olá <b>x</b> <img src="https://x">'), 1,
        'admin com texto + <a> + <img> vai para o caminho HTML');

    is(tweet_content_is_html(disable_escape => 0, use_penhas_avatar => 1, content => 'texto puro'), 0,
        'admin com texto puro mantém pipeline de texto');
    is(tweet_content_is_html(disable_escape => 0, use_penhas_avatar => 1, content => 'leia https://exemplo.com.br/x'), 0,
        'admin com URL em texto puro mantém pipeline de texto (linkfy continua rodando)');

    is(tweet_content_is_html(disable_escape => 0, use_penhas_avatar => 0, content => '<b>x</b>'), 0,
        'usuária com conteúdo semelhante a HTML nunca vai para o caminho HTML');
    is(tweet_content_is_html(disable_escape => 0, use_penhas_avatar => 0, content => 'texto puro'), 0,
        'usuária com texto puro mantém pipeline');
};

subtest 'admin com conteúdo HTML é devolvido cru (href/src preservados)' => sub {
    my $owner = _mk_user(id => 2);

    my $a = '<a href="https://azmina.com.br/colunas/lei-maria-da-penha-exige-enfrentar-racismo/">racismo</a>';
    my $t1 = _format($owner, _mk_row(penhas => 1, author_id => 2, content => $a));
    is($t1->{content}, $a, 'admin + <a>: conteúdo cru, href exato');
    is($t1->{_is_html}, 1, 'admin + <a>: marcado como _is_html');

    my $img = '<img src="https://azmina.com.br/img/lei-maria-da-penha.jpg" alt="x">';
    my $t2 = _format($owner, _mk_row(penhas => 1, author_id => 2, content => $img));
    is($t2->{content}, $img, 'admin + <img>: conteúdo cru, src exato');
    is($t2->{_is_html}, 1, 'admin + <img>: marcado como _is_html');

    my $mixed = 'Olá! Leia <a href="https://azmina.com.br/racismo/">racismo</a> e veja a imagem <img src="https://azmina.com.br/img/lei.jpg">.';
    my $t3 = _format($owner, _mk_row(penhas => 1, author_id => 2, content => $mixed));
    is($t3->{content}, $mixed, 'admin + texto + <a> + <img>: conteúdo cru íntegro');
    is($t3->{_is_html}, 1, 'admin + texto + <a> + <img>: marcado como _is_html');
};

subtest 'reprodução da URL do bug racismo/" >' => sub {
    my $owner = _mk_user(id => 2);
    my $content = '<a href="https://azmina.com.br/colunas/lei-maria-da-penha-exige-enfrentar-racismo/">racismo</a>';

    my $t = _format($owner, _mk_row(penhas => 1, author_id => 2, content => $content));

    unlike($t->{content}, qr{racismo/">https://}, 'sem a corrupção racismo/">https:// (texto visível quebrado)');
    unlike($t->{content}, qr{&quot;}, 'sem entidades de aspas escapadas');
    like($t->{content}, qr{href="https://azmina\.com\.br/colunas/lei-maria-da-penha-exige-enfrentar-racismo/"}, 'href intacto');
};

subtest 'admin com texto puro mantém pipeline anterior (linkfy)' => sub {
    my $owner = _mk_user(id => 2);

    my $t1 = _format($owner, _mk_row(penhas => 1, author_id => 2, content => 'olá admin'));
    is($t1->{content}, 'olá admin', 'admin + texto puro: sem transformação além do pipeline');
    ok(!exists $t1->{_is_html}, 'admin + texto puro: não marcado como _is_html');

    my $t2 = _format($owner, _mk_row(penhas => 1, author_id => 2, content => 'Leia https://azmina.com.br/racismo/ agora'));
    like($t2->{content}, qr{<a href="https://azmina\.com\.br/racismo/">https://azmina\.com\.br/racismo/</a>},
        'admin + texto puro + URL: linkfy continua transformando a URL em link');
    ok(!exists $t2->{_is_html}, 'admin + texto puro + URL: não marcado como _is_html');
};

subtest 'usuárias continuam no pipeline anterior' => sub {
    my $viewer = _mk_user(id => 1);

    my $t1 = _format($viewer, _mk_row(penhas => 0, author_id => 2, content => 'olá usuária'));
    is($t1->{content}, 'olá usuária', 'usuária + texto puro: idêntico ao anterior');
    ok(!exists $t1->{_is_html}, 'usuária + texto puro: sem _is_html');

    my $t2 = _format($viewer, _mk_row(penhas => 0, author_id => 2, content => 'Acesse https://exemplo.com.br/agora'));
    unlike($t2->{content}, qr{<a href}, 'usuária + URL: sem linkfy (como antes)');
    ok(!exists $t2->{_is_html}, 'usuária + URL: sem _is_html');

    my $t3 = _format($viewer, _mk_row(penhas => 0, author_id => 2, content => 'veja <b>isso</b> e <script>alert(1)</script>'));
    is($t3->{content}, 'veja &lt;b&gt;isso&lt;/b&gt; e &lt;script&gt;alert(1)&lt;/script&gt;',
        'usuária + conteúdo semelhante a HTML: escapado como antes');
    ok(!exists $t3->{_is_html}, 'usuária + conteúdo semelhante a HTML: sem _is_html');
};

subtest 'disable_escape=true continua com o comportamento anterior' => sub {
    my $viewer = _mk_user(id => 1);
    my $content = '<p style="text-align:center">atualização</p>';

    my $t = _format($viewer, _mk_row(disable_escape => 1, penhas => 0, author_id => 2, content => $content));
    is($t->{content}, $content, 'disable_escape=true: conteúdo devolvido cru, sem sanitização');
    is($t->{_is_html}, 1, 'disable_escape=true: marcado como _is_html (para o guard de highlights)');
};

subtest 'highlights não modifica href/src de conteúdo HTML' => sub {
    my $config = {
        test => '\\b(racismo)\\b',
        highlights => [
            {
                regexp   => 'racismo',
                noticias => [{id => 1, title => 'Notícia', hyperlink => 'https://noticia.test/x', source => 'S'}],
                id       => 1,
                tag_id   => 1,
                header   => 'Racismo',
            }
        ],
    };

    local $ENV{NEWS_HASH_SALT} = 'salt';
    local $ENV{PUBLIC_API_URL} = 'https://api.test';

    my $html_tweet = {
        id        => 'h1',
        _is_html  => 1,
        content   => '<a href="https://azmina.com.br/colunas/lei-maria-da-penha-exige-enfrentar-racismo/">racismo</a> <img src="https://azmina.com.br/img/lei.jpg">',
        _tags_index => ',,',
    };
    my $plain_tweet = {
        id          => 'c1',
        content     => 'veja racismo agora',
        _tags_index => ',1,',
    };
    my $tweets = [$html_tweet, $plain_tweet];
    my $user   = _mk_user(id => 1);
    my $c      = bless {}, 'FakeC';

    {
        package FakeC;
        sub schema2 { die 'schema2 não deve ser consultado' }
    }

    {
        no warnings 'redefine';
        local *Penhas::Helpers::Timeline::kv = sub { FakeKV->new($config) };
        Penhas::Helpers::Timeline::add_tweets_highlights($c, tweets => $tweets, user_obj => $user);
    }

    is($tweets->[0]{content}, $html_tweet->{content}, 'HTML intacto após highlights (guard pulou)');
    unlike($tweets->[0]{content}, qr{<span style="color: #f982b4">}, 'sem <span> injetado no HTML');
    like($tweets->[0]{content}, qr{href="https://azmina\.com\.br/colunas/lei-maria-da-penha-exige-enfrentar-racismo/"}, 'href intacto');
    like($tweets->[0]{content}, qr{src="https://azmina\.com\.br/img/lei\.jpg"}, 'src intacto');
    like($tweets->[1]{content}, qr{<span style="color: #f982b4">racismo</span>}, 'controle sem _is_html recebeu span (mecanismo ativo)');
};

done_testing;
