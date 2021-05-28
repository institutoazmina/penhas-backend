package Penhas::Controller::Admin::Users;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Penhas::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Mojo::Util qw/humanize_bytes/;
use Penhas::Types qw/DateStr/;

sub au_search {
    my $c = shift;
    $c->use_redis_flash();
    $c->stash(
        template => 'admin/list_users',
    );

    my $valid = $c->validate_request_params(
        rows       => {required => 0, type => 'Int'},
        cliente_id => {required => 0, type => 'Int'},
        next_page  => {required => 0, type => 'Str'},
        nome       => {required => 0, type => 'Str', empty_is_valid => 1, max_length => 99},
        segment_id => {required => 0, type => 'Int'},

        load_delete_form => {required => 0, type => 'Bool'},
    );

    my $dirty = 0;
    my $nome  = $valid->{nome};
    my $rows  = $valid->{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $render_detail = $valid->{cliente_id} && $c->accept_html();
    my $offset        = 0;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'AU:NP';
        $offset = $tmp->{offset};
        $valid->{segment_id} = $tmp->{segment_id} if defined $tmp->{segment_id};
    }

    my $rs = $c->schema2->resultset('Cliente')->search(
        {($valid->{cliente_id} ? ('me.id' => $valid->{cliente_id}) : ())},
        {
            join     => 'clientes_app_activity',
            order_by => \'last_tm_activity DESC NULLS LAST',
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
                  /,
                (
                    $render_detail
                    ? (
                        qw/
                          me.qtde_guardioes_ativos
                          me.qtde_ligar_para_policia
                          me.qtde_login_senha_normal
                          me.modo_camuflado_ativo
                          me.modo_camuflado_atualizado_em
                          me.modo_anonimo_ativo
                          me.modo_anonimo_atualizado_em
                          me.dt_nasc
                          me.cep_cidade
                          me.cep_estado
                          me.perform_delete_at
                          /,
                      )
                    : ()
                )
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
    if ($render_detail) {
        my $cliente = $rs->next or $c->reply_item_not_found();

        my @fields = (
            [id                           => 'ID'],
            [nome_completo                => 'Nome Completo'],
            [status                       => 'Status'],
            [genero                       => 'Gênero'],
            [genero_outro                 => 'Gênero outro'],
            [dt_nasc                      => 'Data de Nascimento', 'tz'],
            [cep_cidade                   => 'Cidade'],
            [cep_estado                   => 'Estado'],
            [qtde_guardioes_ativos        => 'Nº Guardiãs ativas'],
            [qtde_ligar_para_policia      => 'Nº Ligações policia'],
            [qtde_login_senha_normal      => 'Nº Login'],
            [modo_camuflado_ativo         => 'Menu "Modo Camuflado" Ativo?',                 'bool'],
            [modo_camuflado_atualizado_em => '',                                             'tz'],
            [modo_anonimo_ativo           => 'Menu "Estou em situação de violência" Ativo?', 'bool'],
            [modo_anonimo_atualizado_em   => '',                                             'tz'],
            [qtde_audio_aguardando        => 'Nº de aúdios aguardando liberação'],
        );

        foreach my $field (@fields) {
            my ($key, $name, $type) = @$field;

            if ($type && $type eq 'tz') {
                $cliente->{$key} = pg_timestamp2human($cliente->{$key});
            }
            elsif ($type && $type eq 'bool') {
                $cliente->{$key} = $cliente->{$key} ? 'Sim' : 'Não';
            }
        }

        $cliente->{modo_anonimo_ativo} .= ' (atualizado em ' . $cliente->{modo_anonimo_atualizado_em} . ')'
          if $cliente->{modo_anonimo_atualizado_em};
        $cliente->{modo_camuflado_ativo} .= ' (atualizado em ' . $cliente->{modo_camuflado_atualizado_em} . ')'
          if $cliente->{modo_camuflado_atualizado_em};
        $cliente->{qtde_login_senha_normal} .= ' (modo camuflado incluso)';

        my @audios = $c->schema2->resultset('ClientesAudiosEvento')->search(
            {
                'me.cliente_id'        => $cliente->{id},
                'me.requested_by_user' => 1,
                'me.status'            => 'blocked_access',
            },
            {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
        )->all();

        $_->{total_bytes} = humanize_bytes($_->{total_bytes}),
          $_->{audio_duration} = int($_->{audio_duration}) for @audios;

        $cliente->{qtde_audio_aguardando} = scalar @audios;

        $c->stash(
            template => 'admin/user_profile',
            cliente  => $cliente,
            fields   => \@fields,
            audios   => \@audios,

            load_delete_form => $valid->{load_delete_form},
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

sub au_schedule_delete {
    my $c = shift;

    $c->use_redis_flash();
    my $valid = $c->validate_request_params(
        cliente_id  => {required => 1, type => 'Int'},
        delete_date => {required => 1, type => DateStr},
    );

    my $cliente = $c->schema2->resultset('Cliente')->find($valid->{cliente_id})
      or $c->reply_item_not_found();

    $cliente->clientes_active_sessions->delete;
    $cliente->update(
        {
            status            => 'deleted_scheduled',
            perform_delete_at => $valid->{delete_date} . ' 12:00:00',
        }
    );

    if ($c->accept_html()) {
        $c->flash_to_redis({success_message => 'Agendamento de remoção agendado com sucesso!'});
        $c->redirect_to('/admin/users?cliente_id=' . $cliente->id);

        return 0;
    }
    else {
        return $c->render(
            json   => {ok => 1},
            status => 200,
        );
    }
}

sub au_unschedule_delete {
    my $c = shift;

    $c->use_redis_flash();
    my $valid = $c->validate_request_params(
        cliente_id => {required => 1, type => 'Int'},
    );

    my $cliente = $c->schema2->resultset('Cliente')->find($valid->{cliente_id})
      or $c->reply_item_not_found();

    $cliente->update(
        {
            status            => 'active',
            perform_delete_at => undef,
        }
    );

    if ($c->accept_html()) {
        $c->flash_to_redis({success_message => 'Cancelamento do agendamento de remoção executado com sucesso!'});
        $c->redirect_to('/admin/users?cliente_id=' . $cliente->id);

        return 0;
    }
    else {
        return $c->render(
            json   => {ok => 1},
            status => 200,
        );
    }
}

sub au_audio_status {
    my $c = shift;

    $c->use_redis_flash();
    my $valid = $c->validate_request_params(
        audio_evento_id => {required => 1, type => 'Str'},
    );

    my $evento = $c->schema2->resultset('ClientesAudiosEvento')->find($valid->{audio_evento_id})
      or $c->reply_item_not_found();

    $evento->update({status => 'free_access_by_admin'});

    if ($c->accept_html()) {
        $c->flash_to_redis({success_message => 'Audio liberado com sucesso!'});
        $c->redirect_to('/admin/users?cliente_id=' . $evento->cliente_id);

        return 0;
    }
    else {
        return $c->render(
            json   => {ok => 1},
            status => 200,
        );
    }
}

sub ua_delete_message {
    my $c = shift;

    $c->use_redis_flash();
    my $valid = $c->validate_request_params(
        message_id => {required => 1, type => 'Int'},
    );

    my $message = $c->schema2->resultset('ChatSupportMessage')->find($valid->{message_id})
      or $c->reply_item_not_found();

    my $cliente_id = $message->cliente_id;

    $message->delete;

    $c->flash_to_redis({success_message => 'Mensagem removida com sucesso!'});
    $c->redirect_to('/admin/user-messages?cliente_id=' . $cliente_id . '&rows=5');

}

sub ua_send_message {
    my $c = shift;

    $c->use_redis_flash();
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
    my $c = shift;
    $c->use_redis_flash();
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
            cliente => $user_obj,
        },
    );
}

1;
