package Penhas::Controller::Me;
use Mojo::Base 'Penhas::Controller';

use DateTime;
use JSON;

sub check_and_load {
    my $c = shift;

    die 'missing user_id' unless $c->stash('user_id');

    my $user = $c->schema2->resultset('Cliente')->search(
        {
            'id'           => $c->stash('user_id'),
            'status'       => 'active',
            'login_status' => 'OK',
        },
    )->next;

    $c->reply_not_found() unless $user;
    $c->stash('user_obj' => $user);
    $c->stash('user'     => {$user->get_columns});    # nao pode ser o inflacted
    return 1;
}

sub find {
    my $c = shift;

    my %extra;
    my $user     = $c->stash('user');
    my $user_obj = $c->stash('user_obj');

    my $feminino = $user_obj->is_female;
    my $modules  = $user_obj->access_modules;

    my $quiz_session = $c->user_get_quiz_session(user => $user);

    if ($quiz_session) {

        # remove acesso a tudo, o usuario deve completar o quiz
        $modules = {quiz => {}};

        $c->load_quiz_session(session => $quiz_session, user => $user);

        $extra{quiz_session} = $c->stash('quiz_session');

        $c->log->info(to_json($extra{quiz_session}));
    }

    return $c->render(
        json => {
            user_profile => {
                (
                    map { $_ => $user->{$_} }
                      (qw/email cep dt_nasc nome_completo genero minibio raca cpf_prefix nome_social/)
                ),
            },

            modo_camuflado_ativo         => $user->{modo_camuflado_ativo}         ? 1 : 0,
            modo_anonimo_ativo           => $user->{modo_anonimo_ativo}           ? 1 : 0,
            ja_foi_vitima_de_violencia   => $user->{modo_anonimo_ativo}           ? 1 : 0,
            esta_em_situcao_de_violencia => $user->{esta_em_situcao_de_violencia} ? 1 : 0,

            modules => $modules,
            %extra
        },
        status => 200,
    );
}

sub update {
    my $c = shift;


#    return $c->render(json => {id => $user->id}, status => 202,);
}


sub inc_call_police_counter {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');
    $user_obj->update(
        {
            qtde_ligar_para_policia => \'qtde_ligar_para_policia+1',
        }
    );
    $user_obj->cliente_ativacoes_policias->create({created_at => \'NOW()'});

    return $c->render(text => '', status => 204,);
}

1;
