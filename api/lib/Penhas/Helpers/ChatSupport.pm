package Penhas::Helpers::ChatSupport;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Penhas::Utils qw/is_test pg_timestamp2iso_8601 db_epoch_to_etag pg_timestamp2human notifications_enabled/;
use Mojo::Util qw/trim xml_escape/;
use Scope::OnExit;
use Crypt::CBC;
use Crypt::Rijndael;    # AES
use Crypt::PRNG qw(random_bytes);
use Convert::Z85;

our $ForceFilterClientes;
my $reload_app_err_msg = 'Recarregue o app, conversa não pode ser aberta.';


sub setup {
    my $self = shift;

    $self->helper('support_recent_messages' => sub { &support_recent_messages(@_) });

    $self->helper('support_send_message'   => sub { &support_send_message(@_) });
    $self->helper('support_list_message'   => sub { &support_list_message(@_) });
    $self->helper('support_clear_messages' => sub { &support_clear_messages(@_) });

}

sub support_recent_messages {
    my ($c, %opts) = @_;

    my $rows = $opts{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $include_answered = $opts{include_answered} || 0;

    my $offset = 0;
    if ($opts{next_page}) {
        my $tmp = eval { $c->decode_jwt($opts{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'AS:LS';
        $offset = $tmp->{offset};
    }

    my $rs = $c->schema2->resultset('ChatSupport')->search(
        {
            ($include_answered ? () : (last_msg_is_support => 0)),
        },
        {
            join    => 'cliente',
            columns => [
                qw/
                  me.id
                  me.last_msg_at
                  me.last_msg_preview
                  me.last_msg_by
                  cliente.id
                  cliente.nome_completo
                  /
            ],
            order_by     => \'me.last_msg_at DESC',
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

    my $next_page = $c->encode_jwt(
        {
            iss    => 'AS:LS',
            offset => $offset + $cur_count,
        },
        1
    );

    foreach (@rows) {
        $_->{last_msg_at_human} = pg_timestamp2human($_->{last_msg_at});
        $_->{last_msg_by}      ||= '';
        $_->{last_msg_preview} ||= '';

    }

    return {
        rows      => \@rows,
        has_more  => $has_more,
        next_page => $has_more ? $next_page : undef,
    };
}

sub _load_support_room {
    my ($c, %opts) = @_;

    my $user_obj  = $opts{user_obj}  or confess 'missing user_obj';
    my $chat_auth = $opts{chat_auth} or confess 'missing chat_auth';

    $c->reply_invalid_param($reload_app_err_msg, 'chat_auth_invalid')
      unless $chat_auth eq $user_obj->support_chat_auth();

    # carrega a a sala, pra ter o timestamp de ultima msg e etc
    my $session = $user_obj->chat_support;
    if (!$session) {

        # se nao existe, pega um lock
        my ($locked, $lock_key) = $c->kv->lock_and_wait('support:cliente_id' . $user_obj->id);
        on_scope_exit {
            $c->kv->redis->del($lock_key);
        };
        $c->reply_invalid_param('Recurso está em uso, tente novamente', 'already_locked') if !$locked;

        # busca de novo, se ainda nao existir, cria a sala
        $session = $user_obj->chat_support;
        if (!$session) {
            $session = $user_obj->create_related(
                'chat_support',
                {
                    last_msg_at => \'now(6)',
                    created_at  => \'now(6)',
                }
            );
            $session->discard_changes;
        }
    }

    my $other = $c->stash('logged_as_admin')
      ? {
        blocked_me => 0,
        cliente_id => 0,
        activity   => eval { $user_obj->clientes_app_activity->last_activity() } || '',
        apelido    => $user_obj->name_for_admin(),
        avatar_url => $ENV{AVATAR_SUPORTE_URL},
      }
      : {
        blocked_me => 0,
        cliente_id => 0,
        activity   => 'até 48hrs para resposta',
        apelido    => 'Suporte PenhaS',
        avatar_url => $ENV{AVATAR_SUPORTE_URL},
      };

    my $meta = {
        can_send_message => 1,
        did_blocked      => 0,
        is_blockable     => 0,
        last_msg_etag    => db_epoch_to_etag($session->get_column('last_msg_at')),
        header_message   => 'Este é um canal de contato direto com as administradoras do PenhaS.',
        header_warning   => 'Importante: demoramos certa de <b>2 dias para responder as mensagens</b>',
    };

    return ($session, $user_obj, $other, $meta);
}

sub support_send_message {
    my ($c, %opts) = @_;

    my ($session, $user_obj, $other, $meta) = &_load_support_room($c, %opts);
    my $message = defined $opts{message} ? $opts{message} : confess 'missing message';

    slog_info('user_id %d support_send_message chat_id %d', $user_obj->id, $session->id);

    # faz um lock, pra nao ter como ter duas mensagens com o exatamente o mesmo tempo
    # assim evita complicar a paginacao
    my ($locked1, $lock_key1) = $c->kv->lock_and_wait('support:cliente_id' . $user_obj->id);
    on_scope_exit {
        $c->kv->redis->del($lock_key1);
    };

    # se nao conseguir o lock, beleza... pelo menos tentou, mas nao precisa descartar se passou os 15s locked
    my $chat_message;
    my $prev_last_msg_at;
    my $last_msg_at;
    my $logged_as_admin = $c->stash('logged_as_admin') ? 1 : 0;
    $c->schema->txn_do(
        sub {
            # pega o ultimo horario antes da nossa msg
            my $db_info = $c->schema2->resultset('ChatSupport')->search(
                {id => $session->id},
                {
                    columns      => ['me.last_msg_at', {db_now => \'now(6)'}],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                }
            )->next;
            $prev_last_msg_at = $db_info->{last_msg_at};
            $last_msg_at      = $db_info->{db_now} or die 'missing db_now';

            # todas as mensagens salvando termiando com #
            # para na hora que fizer o decrypt verificar a integridade da chave
            $chat_message = $session->chat_support_messages->create(
                {
                    cliente_id    => $user_obj->id,
                    message       => $message,
                    created_at    => $last_msg_at,
                    admin_user_id => ($logged_as_admin ? $c->stash('admin_user')->id() : undef),

                }
            );

            $session->update(
                {
                    last_msg_is_support => $logged_as_admin,
                    last_msg_at         => $last_msg_at,

                    last_msg_preview => length($message) > 100 ? substr($message, 0, 100) . '…' : $message,
                    last_msg_by      => (
                          $logged_as_admin
                        ? $c->stash('admin_user')->first_name()
                        : $user_obj->name_for_admin()
                    ),

                }
            );
        }
    );
    die '$chat_message is not defined' unless $chat_message;
    if (notifications_enabled() && $logged_as_admin) {
        my $subrs = $c->schema2->resultset('ChatClientesNotification')->search(
            {
                cliente_id                 => $user_obj->id,
                pending_message_cliente_id => -1,
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

    return {
        id                 => $chat_message->id,
        prev_last_msg_etag => db_epoch_to_etag($prev_last_msg_at),
        last_msg_etag      => db_epoch_to_etag($last_msg_at),
    };
}

sub support_list_message {
    my ($c, %opts) = @_;

    my ($session, $user_obj, $other, $meta) = &_load_support_room($c, %opts);
    my $rows = $opts{rows} || 10;
    $rows = 5 if !is_test() && ($rows > 100 || $rows < 5);
    my $logged_as_admin = $c->stash('logged_as_admin');

    my $page = $opts{pagination};
    if ($page) {
        $page = eval { $c->decode_jwt($page) };
        $c->reply_invalid_param('paginação inválida', 'pagination')
          if ($page->{iss} || '') ne 'S:X';
    }

    my $rs = $session->chat_support_messages;
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

        if (notifications_enabled() && !$logged_as_admin) {

            # apaga qualquer notificação pendente
            $c->schema2->resultset('ChatClientesNotification')->search(
                {
                    cliente_id                 => $user_obj->id,
                    pending_message_cliente_id => -1,
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
        my $is_me = $row->{admin_user_id} ? 0 : 1;
        $is_me = $is_me ? 0 : 1 if $logged_as_admin;

        $row->{message} = xml_escape($row->{message});

        push @messages, {
            id      => $row->{id},
            message => $row->{message},
            is_me   => $is_me,
            time    => pg_timestamp2iso_8601($row->{created_at})
        };
    }

    $user_obj->update({support_chat_messages_sent => \'support_chat_messages_sent+1'}) if !$logged_as_admin;

    return {
        messages => \@messages,
        other    => $other,
        (
            !$page->{before}
            ? (
                newer => $c->encode_jwt(
                    {
                        iss   => 'S:X',
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
                        iss    => 'S:X',
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

sub support_clear_messages {
    my ($c, %opts) = @_;

    my ($session, $user_obj, $other, $meta) = &_load_support_room($c, %opts);

    $c->schema->txn_do(
        sub {
            $session->chat_support_messages->delete;
        }
    );

    return 1;
}

1;
