package Penhas::Controller::Admin::Users;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Penhas::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;

sub au_search {
    my $c = shift;
    $c->stash(
        template => 'admin/list_users',
    );

    my $valid = $c->validate_request_params(
        rows       => {required => 0, type => 'Int'},
        cliente_id => {required => 0, type => 'Int'},
        next_page  => {required => 0, type => 'Str'},
        nome       => {required => 0, type => 'Str', empty_is_valid => 1, max_length => 99},
        segment_id => {required => 0, type => 'Int'},
    );

    my $dirty = 0;
    my $nome  = $valid->{nome};
    my $rows  = $valid->{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $offset = 0;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'AU:NP';
        $offset = $tmp->{offset};
        $valid->{segment_id} = $tmp->{segment_id} if defined $tmp->{segment_id};
    }

    my $rs = $c->schema2->resultset('Cliente')->search(
        undef,
        {
            join     => 'clientes_app_activity',
            order_by => \'last_tm_activity DESC',
            columns  => [
                {activity => 'clientes_app_activity.last_tm_activity'},
                qw/
                  me.id
                  me.apelido
                  me.nome_completo
                  me.email
                  me.genero
                  me.genero_outro
                  me.status
                  me.qtde_guardioes_ativos
                  me.qtde_ligar_para_policia
                  me.qtde_login_senha_normal
                  /
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    );

    if ($nome) {
        $dirty++;    #nao atualizar o contador do segmento, se tiver.
        $rs = $rs->search(
            {
                '-or' => [
                    \['lower(me.nome_completo) like ?', "\%$nome\%"],
                    \['lower(me.apelido) like ?',       "\%$nome\%"],
                    \['lower(me.email) like ?',         "\%$nome\%"],
                ],
            }
        );
    }

    my $segment;
    if ($valid->{segment_id}) {
        $segment = $c->schema2->resultset('AdminClientesSegment')->find($valid->{segment_id});
        $c->reply_invalid_param('segment_id') unless $segment;
        $rs = $segment->apply_to_rs($c, $rs);
    }

    my ($total_count, @rows);
    if ($valid->{cliente_id} && $c->accept_html()) {
        $rs = $rs->search({'me.id' => $valid->{cliente_id}});
        $c->stash(
            template => 'admin/user_profile',
            cliente  => $rs->next,
            fields   => [
                [id                      => 'ID'],
                [nome_completo           => 'Nome Completo'],
                [status                  => 'Status'],
                [genero                  => 'Gênero'],
                [genero_outro            => 'Gênero outro'],
                [qtde_guardioes_ativos   => 'Nº Guardiãs ativas'],
                [qtde_ligar_para_policia => 'Nº Ligações policia'],
                [qtde_login_senha_normal => 'Nº Login'],

            ]
        );

    }
    else {
        $total_count = $rs->count;
        $segment->update({last_count => $total_count, last_run_at => \'NOW()'}) if $segment && !$dirty;

        $rs   = $rs->search(undef, {rows => $rows + 1, offset => $offset});
        @rows = $rs->all;
    }

    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }

    my $next_page = $c->encode_jwt(
        {
            iss        => 'AU:NP',
            offset     => $offset + $cur_count,
            segment_id => $valid->{segment_id}
        },
        1
    );

    my $segments = $c->schema2->resultset('AdminClientesSegment')->search(
        {
            is_test => is_test() ? 1 : 0,
            status  => 'published',
        },
        {
            columns      => [qw/id label last_count last_run_at/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            order_by     => 'sort'
        }
    );

    return $c->respond_to_if_web(
        json => {
            json => {
                rows        => \@rows,
                has_more    => $has_more,
                next_page   => $has_more ? $next_page : undef,
                total_count => $total_count,
                segments    => [$segments->all]
            }
        },
        html => {
            rows               => \@rows,
            has_more           => $has_more,
            next_page          => $has_more ? $next_page : undef,
            total_count        => $total_count,
            pg_timestamp2human => \&pg_timestamp2human,
            segments           => [$segments->all],
            segment            => $segment,
            segment_id         => $segment ? $segment->id : undef,
        },
    );
}

sub ua_send_message {
    my $c     = shift;
    my $valid = $c->validate_request_params(

        cliente_id => {required => 1, type => 'Int'},
        message    => {required => 1, type => 'Str'},
    );

    my $user_obj = $c->schema2->resultset('Cliente')->find($valid->{cliente_id}) or $c->reply_item_not_found();

    my $ret = $c->support_send_message(
        %$valid,
        chat_auth => $user_obj->support_chat_auth(),
        user_obj  => $user_obj,
    );

    if ($c->accept_html()) {
        $c->redirect_to('/admin/user-messages?cliente_id=' . $user_obj->id . '&rows=5');
        return 0;
    }
    else {
        return $c->render(
            json   => $ret,
            status => 200,
        );
    }
}

sub ua_list_messages {
    my $c     = shift;
    my $valid = $c->validate_request_params(
        cliente_id => {required => 1,     type       => 'Int'},
        rows       => {required => 0,     type       => 'Int'},
        pagination => {type     => 'Str', max_length => 999}
    );

    my $user_obj = $c->schema2->resultset('Cliente')->find($valid->{cliente_id}) or $c->reply_item_not_found();

    my $ret = $c->support_list_message(
        %$valid,
        chat_auth => $user_obj->support_chat_auth(),
        user_obj  => $user_obj,
    );

    $c->stash(
        template => 'admin/list_messages',
        is_chat  => 1,
    );

    return $c->respond_to_if_web(
        json => {json => $ret},
        html => {
            %$ret,
            cliente            => $user_obj,
            pg_timestamp2human => \&pg_timestamp2human
        },
    );
}

sub ua_add_notifications {
    my $c     = shift;
    my $valid = $c->validate_request_params(
        cliente_id      => {required => 0, type => 'Int'},
        segment_id      => {required => 0, type => 'Int'},
        message_title   => {required => 1, type => 'Str', max_length => 200},
        message_content => {required => 1, type => 'Str', max_length => 9999},
    );

    my $rs = $c->schema2->resultset('Cliente')->search(
        undef,
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns      => ['me.id'],
        }
    );

    if ($valid->{segment_id}) {
        my $segment = $c->schema2->resultset('AdminClientesSegment')->find($valid->{segment_id});
        $c->reply_invalid_param('segment_id') unless $segment;
        $rs = $segment->apply_to_rs($c, $rs);
    }
    elsif ($valid->{cliente_id}) {
        $rs = $rs->search({'me.id' => $valid->{cliente_id}});
    }
    else {
        $c->reply_invalid_param('é necessário cliente_id ou segment_id');
    }

    my $message_id;
    my $message_count;
    $c->schema2->txn_do(
        sub {
            my $message_row = $c->schema2->resultset('NotificationMessage')->create(
                {
                    title      => $valid->{message_title},
                    content    => $valid->{message_content},
                    icon       => 0,
                    subject_id => undef,
                    meta       => to_json(
                        {
                            created_by => $c->stash('admin_user')->id,
                            ip         => $c->remote_addr(),
                        }
                    ),
                    created_at => \'now()',
                }
            );
            $message_id = $message_row->id;
            my @clientes = map { $_->{id} } $rs->all;

            $c->schema2->resultset('NotificationLog')->populate(
                [
                    [qw/cliente_id notification_message_id created_at/],
                    map {
                        [
                            $_,
                            $message_id,
                            \'NOW(6)'
                        ]
                    } @clientes
                ]
            );

            $c->user_notifications_clear_cache($_) for @clientes;
            $message_count = scalar @clientes;
        }
    );

    return $c->render(
        json => {
            message => 'Zero resultados encontrado - nenhuma mensagem foi criada!',
        },
    ) unless $message_id;

    return $c->render(
        json => {
            notification_message_id => $message_id,
            message                 => sprintf('Notificação adicionada em %d clientes', $message_count),
        },
    );
}

sub ua_add_notification_get {
    my $c = shift;

    $c->stash(
        template => 'admin/add_notification',
    );
    my $valid = $c->validate_request_params(
        segment_id => {required => 1, type => 'Int'},
    );
    my $segment = $c->schema2->resultset('AdminClientesSegment')->find($valid->{segment_id});
    $c->reply_invalid_param('segment_id') unless $segment;

    return $c->respond_to_if_web(
        json => {},
        html => {
            add_editor => 1,
            segment_id         => $segment->id,
            segment            => $segment,
            pg_timestamp2human => \&pg_timestamp2human
        },
    );
}

1;
