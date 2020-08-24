package Penhas::Helpers::Chat;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Penhas::Utils qw/is_test pg_timestamp2iso_8601/;
use Mojo::Util qw/trim/;
use Scope::OnExit;
use Crypt::CBC;
use Crypt::Rijndael;    # AES
use Crypt::PRNG qw(random_bytes);
use Convert::Z85;

our $ForceFilterClientes;

our %activity_labels = (
    0  => 'há pouco tempo',
    1  => 'há poucos dias',
    2  => 'há poucos dias',
    3  => 'há poucos dias',
    4  => 'há alguns dias',
    5  => 'há alguns dias',
    6  => 'há alguns dias',
    7  => 'há alguns dias',
    8  => 'há algumas semanas',
    9  => 'há algumas semanas',
    10 => 'há algumas semanas',
    11 => 'há algumas semanas',
    12 => 'há algumas semanas',
    13 => 'há algumas semanas',
    14 => 'há algumas semanas',
);

sub setup {
    my $self = shift;

    $self->helper('chat_find_users'    => sub { &chat_find_users(@_) });
    $self->helper('chat_profile_user'  => sub { &chat_profile_user(@_) });
    $self->helper('chat_list_sessions' => sub { &chat_list_sessions(@_) });
    $self->helper('chat_open_session'  => sub { &chat_open_session(@_) });
}

sub _cliente_activity_rs {
    my $c = shift;
    $c->schema2->resultset('ClientesAppActivity')->search(
        {
            'cliente.modo_anonimo_ativo' => '0',
            'cliente.status'             => 'active',

            'cliente.genero' => {in => ['MulherTrans', 'Feminino']},    # equivalente ao &is_female()
        }
    );
}

sub chat_find_users {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $rows     = $opts{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $skills = $opts{skills} ? [split /\,/, $opts{skills}] : undef;

    my $nome = trim(lc($opts{name} || ''));

    my $offset = 0;
    if ($opts{next_page}) {
        my $tmp = eval { $c->decode_jwt($opts{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'U:NP';
        $offset = $tmp->{offset};
    }

    my $rs = &_cliente_activity_rs($c)->search(
        {
            (
                $ForceFilterClientes
                ? ('me.cliente_id' => {'in' => $ForceFilterClientes})
                : ()
            ),
        },
        {
            join    => [{'cliente' => {'cliente_skills' => 'skill'}}],
            columns => [
                {cliente_id => 'me.cliente_id'},
                {apelido    => 'cliente.apelido'},
                {avatar_url => 'cliente.avatar_url'},
                {activity   => \"TIMESTAMPDIFF( MINUTE, me.last_tm_activity, now() )"},
                {skills     => \q|JSON_ARRAYAGG(skill.skill)|},
                'me.last_tm_activity',
            ],
            order_by     => \'me.last_tm_activity DESC',
            group_by     => \'me.id',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            rows         => $rows + 1,
            offset       => $offset,
        }
    );

    if ($nome) {
        $rs = $rs->search(
            {
                '-or' => [
                    \['lower(cliente.nome_completo) like ?', "$nome%"],
                    \['lower(cliente.apelido) like ?',       "$nome%"],
                ],
            }
        );
    }
    if ($skills) {

        # fazendo dessa forma, tem uma feature (ou não)
        # os skills retornandos na lista sao os mesmos do filtro
        # (e os outros que o usuario colcou nao vem)
        $rs = $rs->search(
            {
                '-or' => [
                    map { \['skill.id = ?', $_] } $skills->@*,
                ],
            }
        );
    }

    my @rows      = $rs->all;
    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }


    foreach (@rows) {
        my $user_skills = $_->{skills} ? $_->{skills} =~ /^\[/ ? from_json($_->{skills}) : [$_->{skills}] : undef;
        $_->{skills} = join ', ', sort { $a cmp $b } grep {defined} $user_skills->@* if $user_skills;

        $_->{avatar_url} ||= $ENV{AVATAR_PADRAO_URL};

        $_->{activity} = &_activity_mins_to_label($_->{activity});

    }

    my $next_page = $c->encode_jwt(
        {
            iss    => 'U:NP',
            offset => $offset + $cur_count,
        },
        1
    );

    return {
        rows      => \@rows,
        has_more  => $has_more,
        next_page => $has_more ? $next_page : undef,
    };
}

sub _activity_mins_to_label {
    my $activity = shift;

    # divide por 1440 pra transformar de minuto em dias
    return $activity < 5
      ? 'online'
      : $activity_labels{int($activity / 1440)} || 'há muito tempo';
}

sub chat_profile_user {
    my ($c, %opts) = @_;

    my $user_obj   = $opts{user_obj}   or confess 'missing user_obj';
    my $cliente_id = $opts{cliente_id} or confess 'missing cliente_id';

    my $cliente = $c->schema2->resultset('Cliente')->search(
        {
            'me.id'                 => $cliente_id,
            'me.modo_anonimo_ativo' => '0',
            'me.status'             => 'active',

            'me.genero' => {in => ['MulherTrans', 'Feminino']},    # equivalente ao &is_female()
        },
        {
            join    => {'cliente_skills' => 'skill'},
            columns => [
                {cliente_id => 'me.id'},
                {apelido    => 'me.apelido'},
                {avatar_url => 'me.avatar_url'},
                {minibio    => 'me.minibio'},
                {skills     => \q|JSON_ARRAYAGG(skill.skill)|},
            ],
            group_by     => \'me.id',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->next;
    $c->reply_item_not_found() unless $cliente;

    my $skills = $cliente->{skills} ? from_json($cliente->{skills}) : undef;
    $cliente->{skills} = join ', ', sort { $a cmp $b } grep {defined} $skills->@* if $skills;
    $cliente->{avatar_url} ||= $ENV{AVATAR_PADRAO_URL};
    $cliente->{minibio}    ||= '';

    return {
        profile   => $cliente,
        is_myself => $cliente->{cliente_id} == $user_obj->id ? 1 : 0,
    };
}

sub chat_list_sessions {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $rows     = $opts{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $offset = 0;
    if ($opts{next_page}) {
        my $tmp = eval { $c->decode_jwt($opts{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'U:LS';
        $offset = $tmp->{offset};
    }

    my $rs = $c->schema->resultset('ChatSession')->search(
        {
            '-and' => [
                \['me.participants @> ARRAY[?]::int[]', $user_obj->id],    # @> is contains operator
                                                                           # true if left array contains right array
            ],
        },
        {
            columns      => [qw/id participants last_message_at last_message_by/],
            order_by     => \'me.last_message_at DESC',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            rows         => $rows + 1,
            offset       => $offset,
        }
    );

    my @rows      = $rs->all;
    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }

    my $myself = $user_obj->id;
    my @load_participants;
    foreach my $room (@rows) {
        my ($other_id) = grep { $_ != $myself } $room->{participants}->@*;
        $room->{other_id} = $other_id;
        push @load_participants, $other_id;
    }

    my @chats;
    my $participants;
    my $cliente_activity_rs = &_cliente_activity_rs($c)->search(
        {'me.cliente_id' => {'in' => [@load_participants]}},
        {
            join    => 'cliente',
            columns => [
                {cliente_id => 'me.cliente_id'},
                {apelido    => 'cliente.apelido'},
                {avatar_url => 'cliente.avatar_url'},
                {activity   => \"TIMESTAMPDIFF( MINUTE, me.last_tm_activity, now() )"},
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    );
    while (my $r = $cliente_activity_rs->next) {
        $participants->{$r->{cliente_id}} = $r;
    }

    # TODO remover os bloqueados de ambos os lados

    foreach my $room (@rows) {
        my $other = $participants->{$room->{other_id}};
        next unless $other;    # nao existe mais, banido, ou vc/ele bloqueou, etc...

        push @chats, {
            chat_auth          => &_sign_chat_auth($c, $room->{id}),
            last_message_is_me => $room->{last_message_by} == $myself ? 1 : 0,
            last_message_at    => &pg_timestamp2iso_8601($room->{last_message_at}),
            other_activity     => &_activity_mins_to_label($other->{activity}),
            other_apelido      => $other->{apelido},
            other_avatar_url   => $other->{avatar_url} || $ENV{AVATAR_PADRAO_URL},
        };
    }

    my $next_page = $c->encode_jwt(
        {
            iss    => 'U:LS',
            offset => $offset + $cur_count,
        },
        1
    );

    return {
        rows      => \@chats,
        has_more  => $has_more,
        next_page => $has_more ? $next_page : undef,
    };
}

sub chat_open_session {
    my ($c, %opts) = @_;

    my $user_obj      = $opts{user_obj}   or confess 'missing user_obj';
    my $to_cliente_id = $opts{cliente_id} or confess 'missing cliente_id';

    $c->reply_invalid_param(
        'Não pode abrir uma sala contigo mesmo!',
        'cannot_message_self'
    ) if $user_obj->id == $to_cliente_id;

    my $to_cliente = $c->schema2->resultset('Cliente')->search(
        {
            'me.id'     => $to_cliente_id,
            'me.status' => 'active',
        },
        {
            columns      => [qw/id/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->next;
    $c->reply_item_not_found() unless $to_cliente;

    my @participants_in_order = sort { $a <=> $b } $user_obj->id, $to_cliente->{id};
    my ($locked1, $lock_key1) = $c->kv->lock_and_wait('new_chat:cliente_id' . $participants_in_order[0]);
    my ($locked2, $lock_key2) = $c->kv->lock_and_wait('new_chat:cliente_id' . $participants_in_order[1]);

    on_scope_exit {
        $c->kv->redis->del($lock_key1);
        $c->kv->redis->del($lock_key2)
    };
    $c->reply_invalid_param(
        'Recurso está em uso, tente novamente',
        'already_locked'
    ) if (!$locked1 || !$locked2);

    my $existing = $c->schema->resultset('ChatSession')->search(
        {
            '-and' => [
                \['me.participants = ARRAY[?, ?]::int[]', @participants_in_order]

                  # sempre abrir a sala com o ID menor primeiro,
                  # assim da pra usar o operador de igualdade,
                  # mas tambem poderiamos usar o >@ (overlap)
            ],
        },
        {
            columns      => [qw/id/],
            order_by     => \'me.last_message_at DESC',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->next;

    if (!$existing) {
        $existing = $c->schema->resultset('ChatSession')->create(
            {
                participants       => \@participants_in_order,
                created_at         => \'now()',
                last_message_at    => \'now()',
                last_message_by    => $user_obj->id,
                session_started_by => $user_obj->id,
                session_key        => encode_z85(random_bytes(8)),   # 8 bytes, que viram 10 chars,
                                                                     # que somando com a chave do usuário que
                                                                     # iniciou o chat, resultam em 16 bytes para a chave
                                                                     # que ainda vao passar por um hash md5 ate virar
                                                                     # Rijndael (AES) com 256 bits
            }
        );
        $existing = {id => $existing->id};
    }

    return {
        chat_auth => &_sign_chat_auth($c, $existing->{id}),
        is_test()
        ? (
            _test_only_id => $existing->{id},
          )
        : ()
    };
}


sub x {

#    my $cipher = Crypt::CBC->new(
#        -key    => $key,
#        -cipher => 'Rijndael',
#        -header => 'salt',
#    );

}

sub _sign_chat_auth {
    my ($c, $id) = @_;
    return $c->encode_jwt(
        {
            iss => 'U:C',
            id  => $id,
            exp => time() + 7200,
        },
        1
    );
}

1;
