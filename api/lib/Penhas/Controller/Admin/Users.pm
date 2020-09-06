package Penhas::Controller::Admin::Users;
use Mojo::Base 'Penhas::Controller';
use utf8;

use Penhas::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;

sub au_search {
    my $c = shift;

    my $valid = $c->validate_request_params(
        rows       => {required => 0, type => 'Int'},
        cliente_id => {required => 0, type => 'Int'},
        next_page  => {required => 0, type => 'Str'},
        nome       => {required => 0, type => 'Str'},
    );

    my $nome = $valid->{nome};
    my $rows = $valid->{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $offset = 0;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'AU:NP';
        $offset = $tmp->{offset};
    }
    my $rs = $c->schema2->resultset('Cliente')->search(
        undef,
        {
            join     => 'clientes_app_activity',
            order_by => \'last_tm_activity DESC',
            rows     => $rows + 1,
            offset   => $offset,
            columns  => [
                {activity => 'clientes_app_activity.last_tm_activity'},
                qw/
                  me.id
                  me.apelido
                  me.nome_completo
                  me.email
                  me.genero genero_outro status
                  me.qtde_guardioes_ativos
                  me.qtde_ligar_para_policia
                  me.qtde_login_senha_normal
                  /
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
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

    $rs = $rs->search({'me.id' => $valid->{cliente_id}}) if ($valid->{cliente_id});

    my @rows      = $rs->all;
    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }

    my $next_page = $c->encode_jwt(
        {
            iss    => 'AU:NP',
            offset => $offset + $cur_count,
        },
        1
    );

    my $total_count = $valid->{next_page} ? undef : $rs->count;

    $c->stash(
        template => 'list_users',
    );

    return $c->respond_to_if_web(
        json => {
            json => {
                rows        => \@rows,
                has_more    => $has_more,
                next_page   => $has_more ? $next_page : undef,
                total_count => $total_count,
            }
        },
        html => {
            rows        => \@rows,
            has_more    => $has_more,
            next_page   => $has_more ? $next_page : undef,
            total_count => $total_count || $rs->count,
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

    return $c->render(
        json   => $ret,
        status => 200,
    );
}

sub ua_list_messages {
    my $c     = shift;
    my $valid = $c->validate_request_params(
        cliente_id => {required => 1, type => 'Int'},
    );

    my $user_obj = $c->schema2->resultset('Cliente')->find($valid->{cliente_id}) or $c->reply_item_not_found();

    my $ret = $c->support_list_message(
        %$valid,
        chat_auth => $user_obj->support_chat_auth(),
        user_obj  => $user_obj,
    );

    $c->stash(
        template => 'list_messages',
    );

    return $c->respond_to_if_web(
        json => {json => $ret},
        html => {%$ret},
    );
}

1;