package Penhas::Controller::AnonQuestionnaire;
use Mojo::Base 'Penhas::Controller';
use JSON;
use DateTime;

sub verify_anon_token {
    my $c = shift;

    my $valid = $c->validate_request_params(
        token => {required => 1, type => 'Str', max_length => 100,},
    );

    if ($ENV{ANON_QUIZ_SECRET} && $valid->{token} && $valid->{token} eq $ENV{ANON_QUIZ_SECRET}) {
        return 1;
    }

    $c->reply_invalid_param('invalid token', 'token_invalid', 'token');

    return 0;
}

sub aq_config_get {
    my $c = shift;

    my $config = $c->schema2->resultset('TwitterBotConfig')->next;

    return $c->render(
        json => $config ? from_json($config->config) : {},
    );
}

sub aq_list_get {
    my $c = shift;

    $c->ensure_questionnaires_loaded();

    return $c->render(
        json => {
            questionnaires => [
                map {
                    +{
                        id                         => $_->{id},
                        name                       => $_->{name},
                        end_screen                 => $_->{end_screen},
                        condition                  => $_->{condition},
                        penhas_start_automatically => $_->{penhas_start_automatically} ? 1 : 0,
                        penhas_cliente_required    => $_->{penhas_cliente_required}    ? 1 : 0,

                    }
                } $c->stash('questionnaires')->@*
            ]
        },
    );
}

sub aq_list_post {
    my $c = shift;

    my $valid = $c->validate_request_params(
        questionnaire_id => {required => 1, type => 'Int'},
        init_responses   => {required => 0, type => 'Str'},
        remote_id        => {required => 1, type => 'Str', max_length => 100},
    );

    my $quiz_session = $c->anon_new_quiz_session(%$valid);
    use DDP;
    p $quiz_session;
    $c->load_quiz_session(session => $quiz_session, is_anon => 1);

    $c->log->info(to_json($c->stash('quiz_session')));

    return $c->render(
        json => {quiz_session => $c->stash('quiz_session')},
    );

}

sub aq_history_get {
    my $c = shift;

    my $params = $c->req->params->to_hash;

    my $valid = $c->validate_request_params(
        session_id => {required => 1, type => 'Int'},
    );

    my $quiz_session = $c->anon_load_quiz_session(%$valid);
    $c->load_quiz_session(session => $quiz_session, is_anon => 1);

    $c->log->info(to_json($c->stash('quiz_session')));

    return $c->render(
        json => {quiz_session => $c->stash('quiz_session')},
    );

}

sub aq_process_post {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    my $valid  = $c->validate_request_params(
        session_id => {required => 1, type => 'Int'},
    );

    my $quiz_session = $c->anon_load_quiz_session(%$valid);

    my %return;
    $c->process_quiz_session(is_anon => 1, session => $quiz_session, params => $params);
    $return{quiz_session} = $c->stash('quiz_session');

    $c->log->info(to_json($return{quiz_session}));

    return $c->render(
        json   => \%return,
        status => 200,
    );

}

1;
