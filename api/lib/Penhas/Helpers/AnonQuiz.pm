package Penhas::Helpers::AnonQuiz;
use common::sense;
use Carp qw/croak/;
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use warnings;
use Penhas::Logger;
use Scope::OnExit;


sub setup {
    my ($self, %opts) = @_;


    $self->helper('anon_new_quiz_session'  => sub { &anon_new_quiz_session(@_) });
    $self->helper('anon_load_quiz_session' => sub { &anon_load_quiz_session(@_) });
    $self->helper('anon_ponto_apoio_json'  => sub { &anon_ponto_apoio_json(@_) });

}

sub anon_ponto_apoio_json {
    my ($c, %opts) = @_;

    my $lat = $opts{latitude};
    my $lng = $opts{longitude};

    my $pontos_apoios = $c->ponto_apoio_list(
        latitude  => $lat,
        longitude => $lng,

        max_distance => 50,
        rows         => 3,
        all_columns  => 1,
    );
    my $success = scalar @{$pontos_apoios->{rows}};
    my $ret     = [];

    foreach my $ponto_apoio (@{$pontos_apoios->{rows}}) {

        my $str = $ponto_apoio->{nome};
        $str .= ' ' . $ponto_apoio->{categoria}{nome} if $ponto_apoio->{categoria}{nome};

        if ($ponto_apoio->{ddd} && $ponto_apoio->{telefone1}) {
            $str .= ' telefone +55' . $ponto_apoio->{ddd} . $ponto_apoio->{telefone1};
            $str .= ' e +55' . $ponto_apoio->{ddd} . $ponto_apoio->{telefone2} if $ponto_apoio->{telefone2};
        }

        if ($ponto_apoio->{tipo_logradouro} && $ponto_apoio->{nome_logradouro}) {
            $str .= ' localizado na ' . $ponto_apoio->{tipo_logradouro} . ' ' . $ponto_apoio->{nome_logradouro};
            $str .= defined $ponto_apoio->{numero} ? ', ' . $ponto_apoio->{numero} : ' sem número';
        }

        push @$ret, $str;
    }

    return ($success, to_json($ret));
}

sub anon_load_quiz_session {
    my ($c, %opts) = @_;

    my $session_id = $opts{session_id} // croak 'missing session_id';

    my $session = $c->schema2->resultset('AnonymousQuizSession')->search({'me.id' => $session_id})->next;
    if (!$session) {
        $c->reply_invalid_param('session_id não encontrada', 'session_id_invalid', 'session_id');
    }
    $session = {$session->get_columns};
    log_trace('anon_load_quiz_session:loaded');
    slog_info('Created session anon_load_quiz_session.id:%s', $session->{id});

    $session->{stash}     = from_json($session->{stash});
    $session->{responses} = from_json($session->{responses});

    return $session;
}

sub anon_new_quiz_session {
    my ($c, %opts) = @_;

    my $questionnaire_id = $opts{questionnaire_id} or croak 'missing questionnaire_id';
    my $init_responses   = $opts{init_responses};
    if ($init_responses) {
        $init_responses = eval { from_json($init_responses) };
        if (!$init_responses || ref $init_responses ne 'HASH') {
            $c->reply_invalid_param('invalid json, must be defined and a hash', 'json_invalid', 'init_stash');
        }
    }

    $c->ensure_questionnaires_loaded();

    my $available_quiz;

    foreach my $q ($c->stash('questionnaires')->@*) {
        if ($q->{id} == $questionnaire_id) {
            $available_quiz = $q;
            slog_info('questionnaires_id:%s found!', $q->{id});
        }
    }

    if (!$available_quiz) {
        $c->reply_invalid_param(
            'questionnaire_id não foi encontrado', 'questionnaire_id_not_found',
            'questionnaire_id'
        );
    }


    log_info('Running _init_questionnaire_stash');
    my $stash = eval { &Penhas::Helpers::Quiz::_init_questionnaire_stash($available_quiz, $c, 1) };
    if ($@) {
        my $err = $@;
        slog_error('Running _init_questionnaire_stash FAILED: %s', $err);
        die $@ if is_test();

        #use DDP; p $@;
        $stash = &Penhas::Helpers::Quiz::_get_error_questionnaire_stash($err, $c);
    }
    slog_info('Create new session with stash=%s', to_json($stash));

    my $session = $c->schema2->resultset('AnonymousQuizSession')->create(
        {
            remote_id        => $opts{remote_id},
            questionnaire_id => $available_quiz->{id},
            stash            => to_json($stash),
            responses        => to_json({start_time => time(), %$init_responses}),
            created_at       => DateTime->now->datetime(' '),
        }
    );
    $session = {$session->get_columns};
    log_trace('anon_new_quiz_session:created');
    slog_info('Created session anon_new_quiz_session.id:%s', $session->{id});

    $session->{stash}     = from_json($session->{stash});
    $session->{responses} = from_json($session->{responses});

    return $session;
}

1;