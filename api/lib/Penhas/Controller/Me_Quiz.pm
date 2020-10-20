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

    # se nao for a chave pra assistente, precisa ser um inteiro
    $c->validate_request_params(
        session_id => {required => 1, type => 'Int'},
    );

    my $quiz_session = $c->user_get_quiz_session(user => $user);

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
