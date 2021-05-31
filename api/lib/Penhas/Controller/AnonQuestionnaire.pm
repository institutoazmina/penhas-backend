package Penhas::Controller::AnonQuestionnaire;
use Mojo::Base 'Penhas::Controller';

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


}


1;
