package Penhas::Controller::Guardiao;
use Mojo::Base 'Penhas::Controller';

use DateTime;

sub apply_rps {
    my $c = shift;

    # limite de requests por segundo no IP
    # no maximo 100 request por hora
    my $remote_ip = $c->remote_addr();

    # recortando o IPV6 para apenas o prefixo (18 chars)
    $c->stash(apply_rps_on => substr($remote_ip, 0, 18));
    $c->apply_request_per_second_limit(100, 3600);

    $c->stash(template => 'guardiao/index');

    if ($c->accept_html()) {
        $c->stash(
            faqs => [
                $c->schema2->resultset('FaqTelaGuardiao')->search(
                    {'me.status' => 'published'},
                    {
                        columns      => [qw/id title content_html/],
                        order_by     => 'sort',
                        result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                    }
                )->all()
            ]
        );
    }
    return 1;
}

sub get {
    my $c = shift;

    my $valid = $c->validate_request_params(
        token => {required => 1, type => 'Str', max_length => 100,},
    );

    my $res = $c->guardiao_load_by_token(%$valid)->render_guardiao_public_data();
    return $c->respond_to_if_web(
        json => {json => $res},
        html => {%$res, %$valid},
    );
}

sub post {
    my $c = shift;

    my $valid = $c->validate_request_params(
        token  => {required => 1, type => 'Str', max_length => 100,},
        action => {required => 1, type => 'Str', max_length => 100,},
    );

    my $res = $c->guardiao_update_by_token(%$valid)->render_guardiao_public_data();

    return $c->respond_to_if_web(
        json => {json => $res},
        html => {%$res, %$valid},
    );
}


1;
