package Penhas::Helpers::Chat;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Penhas::Utils;
use Mojo::Util qw/trim xml_escape/;
use Scope::OnExit;
use Crypt::CBC;
use Penhas::CryptCBC2x;
use Crypt::Rijndael;    # AES
use Crypt::PRNG qw(random_bytes);
use Convert::Z85;
use Compress::Zlib;
use Encode;
our $ForceFilterClientes;
my $reload_app_err_msg = 'Recarregue o app, conversa não pode ser aberta.';
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
    my $user_obj = shift;

    $user_obj->helper('chat_find_users'     => sub { &chat_find_users(@_) });
    $user_obj->helper('chat_profile_user'   => sub { &chat_profile_user(@_) });
    $user_obj->helper('chat_list_sessions'  => sub { &chat_list_sessions(@_) });
    $user_obj->helper('chat_open_session'   => sub { &chat_open_session(@_) });
    $user_obj->helper('chat_send_message'   => sub { &chat_send_message(@_) });
    $user_obj->helper('chat_list_message'   => sub { &chat_list_message(@_) });
    $user_obj->helper('chat_manage_block'   => sub { &chat_manage_block(@_) });
    $user_obj->helper('chat_delete_session' => sub { &chat_delete_session(@_) });

}

sub _cliente_activity_rs {
    my $c = shift;
    $c->schema2->resultset('ClientesAppActivity')->search(
        {
            'cliente.status' => 'active',

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
            'cliente.modo_anonimo_ativo' => '0',
            (
                $ForceFilterClientes
                ? ('me.cliente_id' => {'in' => $ForceFilterClientes})
                : ('me.cliente_id' => {'!=' => $user_obj->id})    # nao vir o proprio usuario na lista
            ),
        },
        {
            join    => [{'cliente' => {'cliente_skills' => 'skill'}}],
            columns => [
                {cliente_id => 'me.cliente_id'},
                {apelido    => 'cliente.apelido'},
                {avatar_url => 'cliente.avatar_url'},
                {activity   => \"(extract( epoch from (now() - me.last_tm_activity)) / 60)::int"},
                {skills     => \q|json_agg(skill.skill)|},
            ],
            order_by     => \'me.last_tm_activity DESC',
            group_by     => ['me.id', 'cliente.id'],
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
        $_->{skills} = join ',', sort { $a cmp $b } grep {defined} $user_skills->@* if $user_skills;
        $_->{skills} =~ s/,/, /g;

        $_->{avatar_url} ||= $ENV{AVATAR_PADRAO_URL};

        $_->{activity} = &_activity_mins_to_label($_->{activity});

        delete $_->{last_tm_activity};    # just in case
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
                {skills     => \q|json_agg(skill.skill)|},
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


    my $blocked_users = $user_obj->timeline_clientes_bloqueados_ids;
    my $placeholders  = join ', ' => ('?') x @$blocked_users;

    my $rs = $c->schema->resultset('ChatSession')->search(
        {
            '-and' => [
                \['me.participants @> ARRAY[?]::int[]', $user_obj->id],    # @> is contains operator
                                                                           # true if left array contains right array

                (
                    ## && == overlap, se tiver algum overlap, remove o membro
                    @$blocked_users > 0
                    ? (\[' ( ARRAY[' . $placeholders . ']::int[] && me.participants ) = FALSE', @$blocked_users])
                    : ()
                ),
            ],
            'me.has_message' => 1,
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
                {activity   => \"(extract( epoch from (now() - me.last_tm_activity)) / 60)::int"},
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
            chat_auth          => &_sign_chat_auth($c, id => $room->{id}, uid => $user_obj->id),
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
        support   => &_chat_support($c, user_obj => $user_obj),
        assistant => &_chat_assistant($c, user_obj => $user_obj),
    };
}

sub chat_open_session {
    my ($c, %opts) = @_;

    my $user_obj      = $opts{user_obj}   or confess 'missing user_obj';
    my $to_cliente_id = $opts{cliente_id} or confess 'missing cliente_id';

    $c->reply_invalid_param(
        'Não pode abrir uma sala contigo mesmo!',
        'cannot_message_yourself'
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
                last_message_at    => \'clock_timestamp()',
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

        $c->schema2->resultset('PrivateChatSessionMetadata')->create(
            {
                cliente_id       => $user_obj->id,
                other_cliente_id => $to_cliente->{id},
                started_at       => \'NOW()'
            }
        );
    }


    my $chat_auth = &_sign_chat_auth($c, id => $existing->{id}, uid => $user_obj->id);

    return {
        chat_auth => $chat_auth,
        (
            $opts{prefetch}
            ? (
                prefetch => $c->chat_list_message(
                    chat_auth => $chat_auth,
                    user_obj  => $user_obj,
                ),
              )
            : ()
        ),
        is_test() ? (_test_only_id => $existing->{id},) : ()
    };
}


sub _sign_chat_auth {
    my ($c, %opts) = @_;
    return $c->encode_jwt(
        {
            iss => 'U:C',
            id  => $opts{id},
            u   => $opts{uid},
            exp => time() + 7200,
        },
        1
    );
}

sub _chat_support {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj};

    my $session = $user_obj->chat_support;

    my $ret = {
        chat_auth        => $user_obj->support_chat_auth(),    # só pra quem consumir a API nao usar hardcoded ^^
        other_activity   => '',
        other_apelido    => 'Suporte PenhaS',
        other_avatar_url => $ENV{AVATAR_SUPORTE_URL},
    };
    if ($session) {
        $ret->{last_message_at}    = &pg_timestamp2iso_8601($session->get_column('last_msg_at'));
        $ret->{last_message_is_me} = $session->last_msg_is_support ? 0 : 1;
    }
    else {
        $ret->{last_message_at}    = &pg_timestamp2iso_8601($user_obj->get_column('created_on'));
        $ret->{last_message_is_me} = 0;
    }

    return $ret;
}

sub _chat_assistant {
    my ($c, %opts) = @_;
    my $user_obj = $opts{user_obj};

    return undef unless $user_obj->is_female();

    my $texto = '';

    if ($user_obj->quiz_detectou_violencia_atualizado_em) {
        my $dia = $user_obj->quiz_detectou_violencia_atualizado_em->set_time_zone('America/Sao_Paulo')->dmy('/');

        if ($user_obj->quiz_detectou_violencia()) {
            $texto
              = "De acordo com as respostas do questionário realizado no dia $dia, identifiquei que você estava em situação de risco.";
        }
        else {
            $texto
              = "De acordo com as respostas do questionário realizado no dia $dia, identifiquei que você não estava em situação de violência.";
        }

    }

    my $ret = {
        title      => 'Assistente PenhaS',
        subtitle   => 'Entenda se você está em situação de violência',
        avatar_url => $ENV{ASSISTANT_SUPORTE_URL},

        quiz_session => {
            session_id   => $user_obj->assistant_session_id(),
            current_msgs => [
                (
                    $texto
                    ? (
                        {
                            content => $texto,
                            style   => "normal",
                            type    => "displaytext"
                        }
                      )
                    : ()
                ),
                {
                    content => 'Deseja responder o questionário novamente?',
                    ref     => "reset_questionnaire",
                    type    => "yesno"
                }
            ],
            prev_msgs => undef
        }
    };


    return $ret;

}

sub _load_chat_room {
    my ($c, %opts) = @_;

    my $user_obj  = $opts{user_obj}  or confess 'missing user_obj';
    my $chat_auth = $opts{chat_auth} or confess 'missing chat_auth';

    $chat_auth = eval { $c->decode_jwt($chat_auth) };
    $c->reply_invalid_param($reload_app_err_msg, 'chat_auth_invalid')
      if ($chat_auth->{iss} || '') ne 'U:C';

    # se o token nao eh desse usuario, nao pode carregar a sala
    $c->reply_invalid_param(
        $reload_app_err_msg,
        'chat_auth_invalid_user'
    ) if ($chat_auth->{u} || 0) != $user_obj->id;

    # carrega a session, que é equivalente a sala, e tem a chave das mensagens
    my $session = $c->schema->resultset('ChatSession')->search(
        {id      => $chat_auth->{id}},
        {columns => [qw/id session_started_by participants session_key last_message_at/]}
    )->next;
    $c->reply_invalid_param(
        $reload_app_err_msg,
        'chat_session_not_found'
    ) unless $session;

    # procura o dono da sala, que é quem começou a sala, que tem a outra parte da chave
    my $chat_owner = $c->schema2->resultset('Cliente')->search(
        {id => $session->session_started_by},
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => [qw/id salt_key/],
        }
    )->next;
    $c->reply_invalid_param(
        $reload_app_err_msg,
        'chat_owner_not_found'
    ) unless $chat_owner;

    # just in case, a pessoa precisa participar da sala pra ler as mensagens
    $c->reply_invalid_param(
        $reload_app_err_msg,
        'chat_not_participant'
    ) unless grep { $_ == $user_obj->id } $session->participants->@*;

    # inicia o AES usando as duas chaves como origem
    my $cipher = Crypt::CBC->new(
        -key    => decode_z85($chat_owner->{salt_key}) . decode_z85($session->{session_key}),
        -cipher => 'Rijndael',
        -header => 'salt',
        -pbkdf  => 'pbkdf2'
    );

    # inicia o AES usando as duas chaves como origem
    my $cipher_old = Penhas::CryptCBC2x->new(
        -key    => decode_z85($chat_owner->{salt_key}) . decode_z85($session->{session_key}),
        -cipher => 'Rijndael',
        -header => 'salt',
        -pbkdf  => 'pbkdf2'
    );

    my ($other_id) = grep { $_ != $user_obj->id } $session->participants->@*;

    my $other = $c->schema2->resultset('Cliente')->search(
        {'me.id' => $other_id},
        {
            join    => ['cliente_bloqueios_custom', 'clientes_app_activity'],
            bind    => [$user_obj->id],
            columns => [
                {cliente_id => 'me.id'},
                {apelido    => 'me.apelido'},
                {avatar_url => 'me.avatar_url'},
                {blocked_me => 'cliente_bloqueios_custom.blocked_cliente_id'},
                {activity   => \"(extract( epoch from (now() - clientes_app_activity.last_activity)) / 60)::int"},
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->next;
    if (!$other) {
        $other = {
            blocked_me => 0,
            cliente_id => $other_id,
            apelido    => 'Usuário removido',
            avatar_url => $ENV{AVATAR_PADRAO_URL},
            activity   => '-',
            not_found  => 1,
        };
    }
    else {
        $other->{blocked_me} = $other->{blocked_me} ? 1 : 0;
        $other->{avatar_url} ||= $ENV{AVATAR_PADRAO_URL};
        $other->{activity} = &_activity_mins_to_label($other->{activity});

    }

    my $did_blocked = $user_obj->cliente_bloqueios->search({blocked_cliente_id => $other->{cliente_id}})->count > 0;

    my $blocked = delete $other->{blocked_me};
    my $meta    = {
        can_send_message => $blocked     ? 0 : $did_blocked ? 0 : 1,
        did_blocked      => $did_blocked ? 1 : 0,
        is_blockable     => 1,    # usuarios sempre sao is_blockable, apenas o azmina nao eh
        last_msg_etag    => db_epoch_to_etag($session->get_column('last_message_at')),
        header_message   => '',
        header_warning   => '',
    };
    $meta->{can_send_message} = 0 if delete $other->{not_found};

    return ($cipher, $cipher_old, $session, $user_obj, $other, $meta);
}

sub chat_delete_session {
    my ($c, %opts) = @_;

    my ($cipher, $cipher_old, $session, $user_obj, $other, $meta) = &_load_chat_room($c, %opts);

    my @participants_in_order = sort { $a <=> $b } $session->participants->@*;
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

    $c->schema->txn_do(
        sub {
            $session->chat_messages->delete;
            $session->delete;
        }
    );

    return 1;
}

sub chat_send_message {
    my ($c, %opts) = @_;

    my ($cipher, $cipher_old, $session, $user_obj, $other, $meta) = &_load_chat_room($c, %opts);
    my $message = defined $opts{message} ? $opts{message} : confess 'missing message';

    $c->reply_invalid_param(
        'Para enviar mensagens nesta conversa, desbloquei o outro usuário.',
        'remove_block_to_send_message'
    ) if $meta->{did_blocked};

    $c->reply_invalid_param('Você não pode enviar mensagens nesta conversa.', 'blocked')
      unless $meta->{can_send_message};


    slog_info('user_id %d chat_send_message chat_id %d', $user_obj->id, $session->id);

    # faz um lock, pra nao ter como ter duas mensagens com o exatamente o mesmo tempo
    # assim evita complicar a paginacao
    my @participants_in_order = $session->participants->@*;
    my ($locked1, $lock_key1) = $c->kv->lock_and_wait('new_chat:cliente_id' . $participants_in_order[0]);
    my ($locked2, $lock_key2) = $c->kv->lock_and_wait('new_chat:cliente_id' . $participants_in_order[1]);

    on_scope_exit {
        $c->kv->redis->del($lock_key1);
        $c->kv->redis->del($lock_key2)
    };

    # se nao conseguir o lock, beleza... pelo menos tentou, mas nao precisa descartar se passou os 15s locked
    my $chat_message;
    my $prev_last_msg_at;
    my $last_msg_at;
    $c->schema->txn_do(
        sub {
            # pega o ultimo horario antes da nossa msg
            my $db_info = $c->schema->resultset('ChatSession')->search(
                {id => $session->id},
                {
                    columns => ['me.last_message_at', {db_now => \'clock_timestamp()::timestamp without time zone'}],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                }
            )->next;
            $prev_last_msg_at = $db_info->{last_message_at};
            $last_msg_at      = $db_info->{db_now} or die 'missing db_now';

            my $is_compressed = 0;

            #$message = decode 'utf-8', $message;
            my $buffer            = $message . '#';
            my $message_bytes     = encode('utf8', $message);
            my $buffer_compressed = length($message_bytes) > 48 ? Compress::Zlib::memGzip($message_bytes) : undef;
            if ($buffer_compressed && length($buffer_compressed) < length($buffer)) {
                $buffer        = $buffer_compressed;
                $is_compressed = 1;
            }

            # todas as mensagens salvando termiando com #
            # para na hora que fizer o decrypt verificar a integridade da chave
            $chat_message = $session->chat_messages->create(
                {
                    cliente_id    => $user_obj->id,
                    message       => $cipher->encrypt($buffer),
                    created_at    => $last_msg_at,
                    is_compressed => $is_compressed,
                }
            );

            $session->update(
                {
                    last_message_by => $user_obj->id,
                    last_message_at => $last_msg_at,
                    has_message     => 1,
                }
            );
        }
    );
    die '$chat_message is not defined' unless $chat_message;

    if (notifications_enabled()) {
        my $subrs = $c->schema2->resultset('ChatClientesNotification')->search(
            {
                cliente_id                 => $other->{cliente_id},
                pending_message_cliente_id => $user_obj->id,
            }
        );

        # nao tem mensagem, entao vamos criar uma
        # esse contexto ta dentro do lock ainda
        if ($subrs->count == 0) {
            $subrs->create(
                {
                    messaged_at => \'now()',
                }
            );
        }
    }

    $user_obj->update({private_chat_messages_sent => \'private_chat_messages_sent+1'});

    return {
        id                 => $chat_message->id,
        prev_last_msg_etag => db_epoch_to_etag($prev_last_msg_at),
        last_msg_etag      => db_epoch_to_etag($last_msg_at),
    };
}

sub chat_list_message {
    my ($c, %opts) = @_;

    my ($cipher, $cipher_old, $session, $user_obj, $other, $meta) = &_load_chat_room($c, %opts);
    my $rows = $opts{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 1000 || $rows < 10);

    my $page = $opts{pagination};
    if ($page) {
        $page = eval { $c->decode_jwt($page) };
        $c->reply_invalid_param('paginação inválida', 'pagination')
          if ($page->{iss} || '') ne 'U:X';
    }

    my $rs = $session->chat_messages;
    if ($page->{before}) {
        $rs = $rs->search(
            {'me.created_at' => {'<' => $page->{before}}},
            {
                order_by => \'me.created_at DESC',
            }
        );
    }
    else {
        $rs = $rs->search(
            {
                ($page->{after} ? ('me.created_at' => {'>' => $page->{after}}) : ()),
            },
            {
                order_by => \'me.created_at DESC',
            }
        );

        if (notifications_enabled()) {

            # apaga qualquer notificação pendente
            $c->schema2->resultset('ChatClientesNotification')->search(
                {
                    cliente_id                 => $user_obj->id,
                    pending_message_cliente_id => $other->{cliente_id},
                }
            )->delete;

        }
    }

    $rs = $rs->search(
        undef,
        {
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

    my $row_first = $rows[0]  ? $rows[0]{created_at}  : undef;
    my $row_last  = $rows[-1] ? $rows[-1]{created_at} : undef;

    my @messages;
    my $myself = $user_obj->id;
    foreach my $row (@rows) {

        my $message = $cipher->decrypt($row->{message});
        if ($row->{is_compressed}) {
            $message = Compress::Zlib::memGunzip($message);
            $message = '[erro ao descriptografar mensagem]' unless defined $message;
        }
        else {
            $message = '[erro ao descriptografar mensagem]' unless $message =~ s/#$//;
        }

        if ($message eq '[erro ao descriptografar mensagem]') {
            $message = $cipher_old->decrypt($row->{message});
            if ($row->{is_compressed}) {
                $message = Compress::Zlib::memGunzip($message);
                $message = '[erro ao descriptografar mensagem]' unless defined $message;
            }
            else {
                $message = '[erro ao descriptografar mensagem]' unless $message =~ s/#$//;
            }
        }

        # set internal flag as UTF-8 hint
        $message = decode 'utf-8', $message;

        $message = nl2br(xml_escape($message));
        $message = linkfy($message) if $ENV{LINKFY_CHAT};

        push @messages, {
            id      => $row->{id},
            message => $message . '',
            is_me   => $myself == $row->{cliente_id} ? 1 : 0,
            time    => pg_timestamp2iso_8601($row->{created_at})
        };

    }

    return {
        messages => \@messages,
        other    => $other,
        (
            !$page->{before}
            ? (
                newer => $c->encode_jwt(
                    {
                        iss   => 'U:X',
                        after => $row_first
                          || $page->{after},    # se nao encontrou nenhuma linha, usa o mesmo timestamp do anterior
                    },
                    1
                ),
              )
            : ()
        ),
        has_more => $has_more,
        (
            $has_more
            ? (
                older => $c->encode_jwt(
                    {
                        iss    => 'U:X',
                        before => $row_last,
                    },
                    1
                ),
              )
            : ()
        ),
        meta => $meta,
    };
}

sub chat_manage_block {
    my ($c, %opts) = @_;

    my $user_obj      = $opts{user_obj}   or confess 'missing user_obj';
    my $to_cliente_id = $opts{cliente_id} or confess 'missing cliente_id';
    my $block         = $opts{block};

    $c->reply_invalid_param(
        'Não pode bloquear você mesmo!',
        'cannot_block_yourself'
    ) if $user_obj->id == $to_cliente_id;

    my $rs = $user_obj->cliente_bloqueios->search(
        {
            blocked_cliente_id => $to_cliente_id,
        }
    );

    $c->schema2->txn_do(
        sub {
            $rs->delete;
            if ($block) {
                $rs->create(
                    {
                        created_at => \'now()',
                    }
                );
            }
        }
    );


    return 1;
}

1;
