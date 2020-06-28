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

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        session_id => {required => 1, type => 'Int'},
    );
    my $session_id = delete $params->{session_id};

    $c->render_later, return 1 if $params->{timeout};

    my $user = $c->stash('user');

    my $quiz_session = $c->user_get_quiz_session(user => $user);

    my %extra;
    if ($quiz_session) {

        if ($session_id != $quiz_session->{id}) {
            return $c->render(
                json => {
                    error   => 'session_not_match',
                    message => 'Sessão do quiz desta resposta não confere com a sessão atual. Reinicie o aplicativo.'
                },
                status => 400,
            );
        }

        $c->process_quiz_session(user => $user, session => $quiz_session, params => $params);
        $extra{quiz_session} = $c->stash('quiz_session');

        use JSON;$c->log->info(to_json($extra{quiz_session}));

    }
    else {
        return $c->render(
            json => {
                error   => 'quiz_not_active',
                message => 'Nenhum quiz foi encontrado no momento. Reinicie o aplicativo.'
            },
            status => 400,
        );
    }

    return $c->render(
        json   => {%extra},
        status => 200,
    );
}

1;
