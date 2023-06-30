package Penhas::Controller::Me_Quiz;
use Mojo::Base 'Penhas::Controller';

use DateTime;

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user');
    return 1;
}

sub process {
    my $c = shift;

    my $user     = $c->stash('user');
    my $user_obj = $c->stash('user_obj');

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        session_id => {required => 1, type => 'Str'},
    );
    my $session_id = delete $params->{session_id};

    $c->render_later, return 1 if $params->{timeout};

    if ($session_id && $session_id eq $user_obj->assistant_session_id()) {
        my $return = $c->process_quiz_assistant(user_obj => $user_obj, params => $params);

        return $c->render(
            json   => $return,
            status => 200,
        );
    }


    if ($session_id && $session_id eq $user_obj->mf_assistant_session_id()) {
        my $return = $c->process_mf_assistant(user_obj => $user_obj, params => $params);

        return $c->render(
            json   => $return,
            status => 200,
        );
    }

    # se nao for a chave pra assistente, precisa ser um inteiro
    $c->validate_request_params(
        session_id => {required => 1, type => 'Int'},
    );

    my $mf_sc                         = $user_obj->ensure_cliente_mf_session_control_exists();
    my $current_clientes_quiz_session = $mf_sc->current_clientes_quiz_session();                 #XXXXXXXXX

    # se estiver respondendo o MF, carregamos ele se o Session ID der match no pedido, vamos nele,
    # senão, vai na logica normal [procurar o primeiro chat relevante].
    # pq isso só aqui no POST?
    # o conteudo do chat vem sempre via GET /me, ou /me/chat ou /me/tarefas
    # e ai já tbm tem os tratamentos pra carregar da session apropriadas

    my $quiz_session = $c->user_get_quiz_session(
        user => $user,

        questionnaire_id => (
              $current_clientes_quiz_session && $current_clientes_quiz_session->id() == $session_id
            ? $current_clientes_quiz_session->questionnaire_id()
            : undef
        )

    );

    if (!$quiz_session) {
        return $c->render(
            json => {
                error   => 'quiz_not_active',
                message => 'Nenhum quiz foi encontrado no momento. Reinicie o aplicativo.'
            },
            status => 400,
        );
    }

    if ($session_id != $quiz_session->{id}) {
        return $c->render(
            json => {
                error   => 'session_not_match',
                message => 'Sessão do quiz desta resposta não confere com a sessão atual. Reinicie o aplicativo.'
            },
            status => 400,
        );
    }

    my %return;
    $c->process_quiz_session(user => $user, user_obj => $user_obj, session => $quiz_session, params => $params);
    $return{quiz_session} = $c->stash('quiz_session');

    use JSON;
    $c->log->info(to_json($return{quiz_session}));

    return $c->render(
        json   => \%return,
        status => 200,
    );

}

1;
