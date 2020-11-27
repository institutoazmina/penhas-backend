package Penhas::Controller::Admin::Notifications;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Penhas::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Mojo::DOM;


sub unft_crud {
    my $c = shift;

    $c->use_redis_flash();

    my $valid = $c->validate_request_params(
        cliente_id              => {required => 0, type => 'Int'},
        segment_id              => {required => 0, type => 'Int'},
        action                  => {required => 0, type => 'Str'},
        notification_message_id => {required => 0, type => 'Int'},
        message_title           => {required => 1, type => 'Str', max_length => 200},
        message_content         => {required => 1, type => 'Str', max_length => 9999},
    );

    if ($valid->{notification_message_id}) {
        my $notification_message
          = $c->schema2->resultset('NotificationMessage')->find($valid->{notification_message_id})
          or $c->reply_item_not_found();

        if ($valid->{action} && $valid->{action} eq 'delete') {
            $notification_message->notification_logs->delete;
            $notification_message->delete;
            return $c->respond_to_if_web(
                json => {
                    text   => '',
                    status => 204,
                },
                html => sub {
                    $c->flash_to_redis({success_message => 'Removido com sucesso!'});
                    $c->redirect_to('/admin/notifications');
                }
            );
        }

        $notification_message->update(
            {
                title   => $valid->{message_title},
                content => $valid->{message_content},
            }
        );

        return $c->respond_to_if_web(
            json => {
                text   => '',
                status => 204,
            },
            html => sub {
                $c->flash_to_redis({success_message => 'Salvo com sucesso!'});
                $c->redirect_to('/admin/message-detail?id=' . $notification_message->id);
            }
        );
    }

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
            my @clientes = map { $_->{id} } $rs->all;
            $message_count = scalar @clientes;
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
                            count      => $message_count,
                        }
                    ),
                    created_at => \'now()',
                }
            );
            $message_id = $message_row->id;

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
        }
    );

    return $c->render(
        json => {
            message => 'Zero resultados encontrado - nenhuma mensagem foi criada!',
        },
    ) unless $message_id;

    my $message = sprintf('Notificação adicionada em %d clientes', $message_count);
    return $c->respond_to_if_web(
        json => {
            json => {
                notification_message_id => $message_id,
                message                 => $message,
            },
        },
        html => sub {
            $c->flash_to_redis({success_message => $message});
            $c->redirect_to('/admin/message-detail?id=' . $message_id);
        }
    );
}

sub unft_new_template {
    my $c = shift;

    $c->use_redis_flash();
    $c->stash(template => 'admin/add_notification');
    my $valid = $c->validate_request_params(
        segment_id => {required => 1, type => 'Int'},
    );
    my $segment = $c->schema2->resultset('AdminClientesSegment')->find($valid->{segment_id});
    $c->reply_invalid_param('segment_id') unless $segment;

    return $c->respond_to_if_web(
        json => {},
        html => {
            add_editor => 1,
            segment_id => $segment->id,
            segment    => $segment,
        },
    );
}

sub unft_explore {
    my $c = shift;

    $c->use_redis_flash();

    $c->stash(template => 'admin/add_notification');
    my $valid = $c->validate_request_params(
        id => {required => 1, type => 'Int'},
    );
    my $notification_message = $c->schema2->resultset('NotificationMessage')->find($valid->{id});
    $c->reply_invalid_param('id') unless $notification_message;

    return $c->respond_to_if_web(
        json => {},
        html => {
            add_editor           => 1,
            notification_message => $notification_message,
        },
    );
}

sub unft_list {
    my $c = shift;

    $c->use_redis_flash();
    $c->stash(
        template => 'admin/list_notifications',
    );

    my $valid = $c->validate_request_params(
        rows      => {required => 0, type => 'Int'},
        next_page => {required => 0, type => 'Str'},
    );
    my $rows = $valid->{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $offset = 0;
    if ($valid->{next_page}) {
        my $tmp = eval { $c->decode_jwt($valid->{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'NFT:NP';
        $offset = $tmp->{offset};
    }

    my $rs = $c->schema2->resultset('NotificationMessage')->search(
        {
            'me.subject_id' => undef,
        },
        {
            order_by     => \'me.id DESC',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    );

    $rs = $rs->search(undef, {rows => $rows + 1, offset => $offset});
    my @rows = $rs->all;

    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }

    foreach (@rows) {
        my $dom = Mojo::DOM->new($_->{content});
        $_->{content_text} = $dom->all_text;
    }

    my $next_page = $c->encode_jwt(
        {
            iss    => 'NFT:NP',
            offset => $offset + $cur_count,
        },
        1
    );

    return $c->respond_to_if_web(
        json => {
            json => {
                rows      => \@rows,
                has_more  => $has_more,
                next_page => $has_more ? $next_page : undef,
            }
        },
        html => {
            rows      => \@rows,
            has_more  => $has_more,
            next_page => $has_more ? $next_page : undef,
        },
    );
}


1;
