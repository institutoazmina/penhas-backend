package Penhas::Controller::Me_Tarefas;
use Mojo::Base 'Penhas::Controller';

use DateTime;
use Penhas::Types qw/TweetID/;

use Penhas::Logger;
use JSON qw/from_json to_json/;

sub assert_user_perms {
    my $c = shift;

    $c->assert_user_has_module('tweets');
    return 1;
}


sub me_t_list {

    my $c = shift;

    my $params = $c->req->params->to_hash;
    my $valid  = $c->validate_request_params(
        modificado_apos => {required => 1, type => 'Int'},
    );

    my $result = $c->cliente_lista_tarefas(
        user_obj => $c->stash('user_obj'),
        %$valid,
    );

    slog_info('tarefas ok');

    return $c->render(
        json => {
            %$result,
            %{$c->cliente_mf_assistant(user_obj => $c->stash('user_obj'))}
        },
        status => 200,
    );
}

sub _sync_validate_and_process_params {
    my $c      = shift;
    my $params = shift;

    my $valid;
    if ($params->{remove}) {
        $valid = $c->validate_params(
            $params,
            id     => {required => 1, type => 'Int'},
            remove => {required => 1, type => 'Bool'},
        );
    }
    else {
        $valid = $c->validate_params(
            $params,
            id             => {required => 1, type => 'Int'},
            checkbox_feito => {required => 1, type => 'Bool'},
            campo_livre    => {required => 0, type => 'Str', max_length => 50000, empty_is_valid => 1},
        );

        if ($valid->{campo_livre}) {
            my $decoded = eval { from_json($valid->{campo_livre}) };
            if ($@) {
                die {
                    error   => 'form_error',
                    field   => 'campo_livre',
                    reason  => 'invalid',
                    message => 'json inválido',
                    status  => 400
                };
            }
        }
    }

    return $valid;
}

sub _sync_perform_actions {
    my $c     = shift;
    my $valid = shift;

    my $result = $c->cliente_sync_lista_tarefas(
        user_obj => $c->stash('user_obj'),
        %$valid,
    );

    return $result;
}

sub me_t_batch_sync {
    my $c = shift;

    my $params = $c->req->json;
    die {
        error   => 'form_error',
        field   => 'body',
        reason  => 'invalid',
        message => 'INVALID JSON, body must be an array!',
        status  => 400
    } if (ref $params ne 'ARRAY');

    my $updated = 0;
    my $removed = 0;

    $c->schema2->txn_do(
        sub {
            for my $param (@$params) {
                if (exists $param->{campo_livre} && ref $param->{campo_livre}) {
                    $param->{campo_livre} = to_json($param->{campo_livre});
                }

                my $form = _sync_validate_and_process_params($c, $param);
                _sync_perform_actions($c, $form);

                if ($form->{remove}) {
                    $removed++;
                }
                else {
                    $updated++;
                }
            }
        }
    );

    return $c->render(
        json => {
            updated => $updated,
            removed => $removed,
        },
        status => 200,
    );
}


sub me_t_sync {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    my $valid = _sync_validate_and_process_params($c, $params);

    _sync_perform_actions($c, $valid);

    return $c->render(
        text   => '',
        status => 204,
    );
}


sub me_t_nova {

    my $c = shift;

    my $params = $c->req->params->to_hash;

    my $valid = $c->validate_request_params(
        titulo    => {required => 1, type => 'Str', max_length => 512,  min_length => 1,},
        descricao => {required => 1, type => 'Str', max_length => 2048, min_length => 1},
        agrupador => {required => 1, type => 'Str', max_length => 120,  min_length => 1},
        token     => {required => 1, type => 'Str', max_length => 120,  min_length => 1},


        # enviar 1 pra mudar o tipo para [checkbox_contato]
        checkbox_contato => {required => 0, type => 'Bool'},
    );

    my $result = $c->cliente_nova_tarefas(
        user_obj => $c->stash('user_obj'),
        %$valid,
    );

    return $c->render(
        json   => $result,
        status => 200,
    );
}


1;
