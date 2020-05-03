package Penhas::Helpers::Quiz;
use common::sense;
use Penhas::Directus;
use Carp qw/croak/;
use Digest::MD5 qw/md5_hex/;
use Penhas::Utils qw/tt_test_condition tt_render is_test/;
use JSON;
use Readonly;
use DateTime;
use Penhas::Logger;
use Scope::OnExit;

# a chave do cache é composta por horarios de modificações do quiz_config e questionnaires
use Penhas::KeyValueStorage;

sub _new_displaytext {
    {
        type       => 'displaytext',
        content    => $_[0],
        style      => 'error',
        _relevance => '1',
    }
}

sub setup {
    my $self = shift;

    $self->helper(
        'ensure_questionnaires_loaded' => sub {
            my ($c, %opts) = @_;

            return 1 if $c->stash('questionnaires');

            my $questionnaires = $c->directus->search(
                table => 'questionnaires',
                form  => {
                    (
                        $ENV{FILTER_QUESTIONNAIRE_IDS}
                        ? ('filter[id][in]' => $ENV{FILTER_QUESTIONNAIRE_IDS})
                        : ('filter[active][eq]' => '1')
                    ),

                    fields => '*,quiz_configs.modified_on'
                }
            );


            foreach my $q (@{$questionnaires->{data}}) {
                my $md5 = md5_hex($q->{modified_on} . join ',', map { $_->{modified_on} } $q->{quiz_configs}->@*);

                $q->{quiz_config}
                  = $c->load_quiz_config(questionnaire_id => $q->{id}, modified_hash => $md5);
            }

            $c->stash(questionnaires => $questionnaires->{data});

        }
    );

    $self->helper(
        'load_quiz_config' => sub {
            my ($c, %opts) = @_;

            my $id        = $opts{questionnaire_id};
            my $cachehash = $opts{modified_hash};
            my $kv        = Penhas::KeyValueStorage->instance;

            my $cachekey = "QuizConfig:$id:$cachehash";
            Readonly::Array my @config => @{
                $kv->redis_get_cached_or_execute(
                    $cachekey,
                    86400 * 7,    # 7 days
                    sub {
                        return $c->directus->search(
                            table => 'quiz_config',
                            form  => {
                                'status'                       => 'published',
                                'filter[questionnaire_id][eq]' => $id,
                                'sort'                         => 'sort,id'
                            }
                        )->{data};
                    }
                )
            };

            #use DDP;
            #p \@config;
            return \@config;
        }
    );


    $self->helper(
        'user_get_quiz_session' => sub {
            my ($c, %opts) = @_;
            my $user = $opts{user} or croak 'missing user';

            Log::Log4perl::NDC->push('user_get_quiz_session user_id:' . $user->{id});
            on_scope_exit { Log::Log4perl::NDC->pop };

            $c->ensure_questionnaires_loaded();

            my @available_quiz;
            my $vars = &_quiz_get_vars($user);

            foreach my $q ($c->stash('questionnaires')->@*) {
                if (tt_test_condition($q->{condition}, $vars)) {
                    push @available_quiz, $q;
                    slog_info('questionnaires_id:%s criteria matched "%s"', $q->{id}, $q->{condition});
                }
                else {
                    slog_info('questionnaires_id:%s criteria NOT matched "%s"', $q->{id}, $q->{condition});
                }
            }

            log_info('user has no quiz available'), return if !@available_quiz;

            # tem algum quiz true, entao vamos remover os que o usuario ja completou

            my %is_finished = map { $_->{questionnaire_id} => 1 } $c->directus->search(
                table => 'clientes_quiz_session',
                form  => {

                    # finished_at IS NOT NULL
                    'filter[finished_at][nnull]'   => 1,
                    'filter[cliente_id][eq]'       => $user->{id},
                    'filter[questionnaire_id][in]' => (join ',', map { $_->{id} } @available_quiz),

                    # só precisamos deste campo
                    'fields' => 'questionnaire_id'
                }
            )->{data}->@*;

            # esta muito simples por enquanto, vou ordenar pelo nome
            # e deixar apenas um ativo questionario por vez
            foreach my $q (sort { $a->{name} cmp $b->{name} } @available_quiz) {

                Log::Log4perl::NDC->push('questionnaires_id:' . $q->{id});
                on_scope_exit { Log::Log4perl::NDC->pop };

                # pula se ja respondeu tudo
                log_info('is already finished'), next if $is_finished{$q->{id}};

                # procura pela session deste quiz, se nao existir precisamos criar uma
                my $session = $c->directus->search_one(
                    table => 'clientes_quiz_session',
                    form  => {
                        'filter[cliente_id][eq]'       => $user->{id},
                        'filter[questionnaire_id][eq]' => $q->{id},
                    }
                );
                if (!$session) {
                    log_info('Running _init_questionnaire_stash');
                    my $stash = eval { &_init_questionnaire_stash($q, $c) };
                    if ($@) {
                        my $err = $@;
                        slog_error('Running _init_questionnaire_stash FAILED: %s', $err);
                        die $@ if is_test();

                        #use DDP; p $@;
                        $stash = &_get_error_questionnaire_stash($err, $c);
                    }

                    slog_info('Create new session with stash=%s', to_json($stash));

                    $session = $c->directus->create(
                        table => 'clientes_quiz_session',
                        form  => {
                            cliente_id       => $user->{id},
                            questionnaire_id => $q->{id},
                            stash            => $stash,
                            responses        => {start_time => time()}
                        }
                    )->{data};
                    log_trace('clientes_quiz_session:created');
                    slog_info('Created session clientes_quiz_session.id:%s', $session->{id});
                }
                else {
                    log_trace('clientes_quiz_session:loaded');
                    slog_info(
                        'Loaded session clientes_quiz_session.id:%s with stash=%s', $session->{id},
                        to_json($session->{stash})
                    );
                }

                return $session;
            }

            # todos os quiz estao finished
            return;
        }
    );


    $self->helper('load_quiz_session'    => sub { &load_quiz_session(@_) });
    $self->helper('process_quiz_session' => sub { &process_quiz_session(@_) });


}

sub _quiz_get_vars {
    my ($user, $responses) = @_;

    #use DDP;
    #p [$user, $responses];
    return {cliente => $user, %{$responses || {}}};
}

sub load_quiz_session {
    my ($c, %opts) = @_;


    my $user    = $opts{user}    or croak 'missing user';
    my $session = $opts{session} or croak 'missing session';

    my $update_db    = $opts{update_db} || 0;
    my @preprend_msg = $opts{preprend_msg} ? @{$opts{preprend_msg}} : ();
    my $responses    = $session->{responses};
    my $stash        = $session->{stash};

    my $vars = &_quiz_get_vars($user, $responses);

    my $current_msgs = $stash->{current_msgs} || [];

    my $is_finished        = $stash->{is_finished};
    my $add_more_questions = &any_has_relevance($vars, $current_msgs) == 0;

    # se chegar em 0, estamos em loop...
    my $loop_detection = 10;
  ADD_QUESTIONS:
    if (--$loop_detection < 0) {
        $c->stash(
            quiz_session => {
                session_id   => $session->{id},
                current_msgs => [&_new_displaytext('Loop no quiz detectado, entre em contato com o suporte')],
                prev_msgs    => $stash->{prev_msgs}
            }
        );
        return;
    }

    # nao tem nenhuma relevante pro usuario, pegar todas as pending ate um input
    if ($add_more_questions) {

        my $is_last_item = 0;
        do {
            my $item = shift $stash->{pending}->@*;
            if ($item) {

                # pegamos um item que eh input, entao vamos sair do loop nesta vez
                $is_last_item = 1 if $item->{type} ne 'displaytext';

                # joga item pra lista de msg correntes
                push $current_msgs->@*, $item;
            }
            else {
                $is_last_item = 1;
            }

            $update_db++;
        } while !$is_last_item;

        # chegamos no final do chat
        if ($stash->{pending}->@* == 0) {
            $stash->{is_eof} = 1;
            $update_db++;
        }
    }

    my @frontend_msg;

    foreach my $q ($current_msgs->@*) {
        my $has = &has_relevance($vars, $q);
        $q->{_currently_has_relevance} = $has;
        push @frontend_msg, &_render_question($q, $vars) if $has;
    }

    # nao teve nenhuma relevante, adiciona mais questoes,
    # mesmo se tiver um botao agora que nao esta visivel
    # isso faz com que seja possível desenhar um fluxo onde uma pergunta no futuro
    # muda reativa a visibilidade de uma pergunta do passado
    # embora isso possa ser uma bad-pratice, pois isso pode fazer com que
    # a pergunta atual do 'nada' fique com dois inputs, caso mal feita a logica
    # ja que essa situacao nao esta testada no app.
    if (!@frontend_msg) {
        if (!$stash->{is_eof}) {
            $add_more_questions = 1;
            goto ADD_QUESTIONS;
        }
        else {
            if (!$opts{caller_is_process}) {

                # acabou sem um input [pois isso aqui eh chamado no GET],
                # vou colocar um input padrao de finalizar
                $current_msgs = [
                    {
                        type       => 'button',
                        content    => 'Fim!',
                        _relevance => '1',
                        ref        => 'btn',
                        action     => 'reload',
                        label      => 'Continuar',
                    }
                ];
            }
        }

    }

    $stash->{current_msgs} = $current_msgs;

    # se teve modificações, entamos vamos escrever a stash de volta no banco
    # isso eh necessario pois o metodo que o metodo que receba as respostas nao precise "renderizar" o chat
    # [chamar propria rotina]
    # e tambem para evitar que ele avance o chat ou receber uma resposta sem sentido mas avançar o chat
    if ($update_db) {

        slog_info("updating stash to %s",     to_json($stash));
        slog_info("updating responses to %s", to_json($responses));

        #use DDP; p $stash;
        $c->directus->update(
            table => 'clientes_quiz_session',
            id    => $session->{id},
            form  => {
                stash     => $stash,
                responses => $responses,
                (
                    $stash->{is_finished}
                    ? (finished_at => DateTime->now->datetime(' '))
                    : ()
                )
            }
        )->{data};
    }

    if (exists $stash->{is_finished} && $stash->{is_finished}) {
        $c->stash(
            'quiz_session' => {
                finished => 1,
            }
        );
    }
    else {
        $c->stash(
            'quiz_session' => {
                current_msgs => [@preprend_msg, @frontend_msg],
                session_id   => $session->{id},
                prev_msgs    => $opts{caller_is_process}
                ? undef
                : [map { &_render_question($_, $vars) } $stash->{prev_msgs}->@*],
            }
        );
    }

}

sub _render_question {
    my ($q, $vars) = @_;

    my $public = {};
    while (my ($k, $v) = each $q->%*) {

        # ignora as chaves privatas
        next if $k =~ /^_/;

        if ($k eq 'options' && ref $v eq 'ARRAY') {

            my @new_options;

            # tomar cuidado pra nunca sobreescrever o valor na referencia original
            foreach my $option ($v->@*) {
                push @new_options, {
                    %$option,
                    display => tt_render($option->{display}, $vars),
                };
            }

            $public->{$k} = \@new_options;

        }
        else {

            $public->{$k} = $k =~ /content/ ? tt_render($v, $vars) : $v;

        }

    }

    return $public;
}


sub process_quiz_session {
    my ($c, %opts) = @_;

    my $user    = $opts{user}          or croak 'missing user';
    my $session = $opts{session}       or croak 'missing session';
    my $params  = delete $opts{params} or croak 'missing params';

    my $stash        = $session->{stash};
    my $current_msgs = $stash->{current_msgs} || [];
    my $responses    = $session->{responses};

    my @preprend_msg;

    my $update_user_skills;
    my $have_new_responses;
  QUESTIONS:
    foreach my $msg (reverse $current_msgs->@*) {

        # se ela nao tava na tela, nao podemos processar as respostas
        next unless $msg->{_currently_has_relevance};

        my $ref = $msg->{ref};
        next unless $ref;

        if (exists $params->{$ref}) {
            my $val  = $params->{$ref} || '';
            my $code = $msg->{_code};
            die sprintf "missing `_code` on message %s", to_json($msg) unless $code;

            if ($msg->{type} eq 'yesno') {

                if ($val =~ /^(Y|N)$/) {

                    # processa a questao que o cadastro (code) eh unico
                    # mas esta espalhada em varias mensagens
                    if (exists $msg->{_sub}) {
                        $responses->{$msg->{_sub}{ref}} = $val;

                        if (exists $responses->{$code}) {
                            if ($responses->{$code} !~ /^\d+/) {
                                push @preprend_msg,
                                  &_new_displaytext(
                                    sprintf(
                                        'Erro na configuração do quiz! code `%s` já tem um valor não númerico, logo não pode-se somar uma resposta de power2',
                                        $code
                                    )
                                  );
                                last QUESTIONS;
                            }

                            $responses->{$code} += $msg->{_sub}{p2a} if $val eq 'Y';
                        }
                        else {
                            $responses->{$code} = $msg->{_sub}{p2a} if $val eq 'Y';
                        }

                        $code = $msg->{_sub}{code} . '_' . $msg->{_sub}{p2a};
                    }

                    $responses->{$code} = $val;
                    $msg->{display_response} = $val eq 'Y' ? 'Sim' : 'Não';
                    $have_new_responses++;
                }
                else {
                    push @preprend_msg, &_new_displaytext(sprintf('Campo %s deve ser Y ou N', $ref));
                }
            }
            elsif ($msg->{type} eq 'text') {

                $responses->{$code} = $val;
                $msg->{display_response} = $val;
                $have_new_responses++;

            }
            elsif ($msg->{type} eq 'multiplechoices') {

                # lista de ate 999 numeros
                if (defined $val && length $val <= 6000 && $val =~ /^(\d{1,4},){0,999}\d{1,4}$/a) {

                    my $reverse_index = {map { $_->{index} => $_->{display} } $msg->{options}->@*};

                    my $output       = '';
                    my $output_human = '';
                    foreach my $index (split /,/, $val) {

                        # pula caso venha opcoes invalidas
                        next unless defined $reverse_index->{$index};

                        $output_human .= $reverse_index->{$index} . ', ';
                        $output       .= $index . ',';

                        if (exists $msg->{_skills}) {
                            $update_user_skills = {} unless defined $update_user_skills;
                            $update_user_skills->{set}{$msg->{_skills}[$index]} = 1;
                        }
                    }
                    chop($output_human);    # rm espaco
                    chop($output_human);    # rm virgula
                    chop($output);          # rm virgula

                    $responses->{$code} = $output;
                    $msg->{display_response} = $output_human;
                    $have_new_responses++;

                }
                else {
                    push @preprend_msg, &_new_displaytext(sprintf('Campo %s deve uma lista de números', $ref));
                }

            }
            elsif ($msg->{type} eq 'button') {

                # reiniciar o fluxo
                if ($msg->{_reset}) {
                    $c->ensure_questionnaires_loaded();
                    foreach my $q ($c->stash('questionnaires')->@*) {
                        next unless $q->{id} == $session->{questionnaire_id};
                        $stash     = &_init_questionnaire_stash($q, $c);
                        $responses = {start_time => time()};
                        $have_new_responses++;
                        last;
                    }
                }
                else {
                    $responses->{$code} = $msg->{action};
                    $msg->{display_response} = $msg->{label};
                    $have_new_responses++;

                    if ($stash->{is_eof}) {
                        $stash->{is_finished} = 1;
                    }
                }

            }
            else {
                push @preprend_msg, &_new_displaytext(sprintf('typo %s não foi programado!', $msg->{type}));
            }

        }
        else {
            push @preprend_msg, &_new_displaytext(sprintf('Campo %s nao foi enviado', $ref));
        }

        # vai embora, pois so devemos ter 1 resposta por vez
        # pelo menos eh assim que eu imagino o uso por enquanto
        last QUESTIONS if $have_new_responses;
    }

    # teve respostas, na teoria seria mover as atuais para o "prev_msgs",
    # mas só devemos movimentar o que estava relevante momento anteriores as respostas
    if ($have_new_responses) {

        my @keeped;

        for my $msg ($current_msgs->@*) {
            if (!$msg->{_currently_has_relevance}) {
                push @keeped, $msg;
                next;
            }
            else {
                push $stash->{prev_msgs}->@*, $msg;
            }
        }

        $stash->{current_msgs} = $current_msgs = \@keeped;
        $session->{responses}  = $responses;

        # salva as respostas (vai ser chamado no load_quiz_session)
        $opts{update_db} = 1;

        # chegou ate aqui, sem dar crash, vamos atualizar os skills do usuario
        if (defined $update_user_skills->{set}) {
            $c->cliente_set_skill(user => $user, skills => [keys $update_user_skills->{set}->%*]);
        }

    }

    $c->load_quiz_session(
        %opts,
        preprend_msg      => \@preprend_msg,
        caller_is_process => 1,
    );

}

sub has_relevance {
    my ($vars, $msg) = @_;

    return 1 if $msg->{_relevance} eq '1';
    return 1 if tt_test_condition($msg->{_relevance}, $vars);
    return 0;
}

sub any_has_relevance {
    my ($vars, $msgs) = @_;

    foreach my $q ($msgs->@*) {
        return 1 if $q->{_relevance} eq '1';
        return 1 if has_relevance($vars, $q);
    }

    return 0;
}

sub _init_questionnaire_stash {
    my $questionnaire = shift;
    my $c             = shift;

    die "AnError\n" if exists $ENV{DIE_ON_QUIZ};

    my @questions;
    foreach my $qc ($questionnaire->{quiz_config}->@*) {

        my $relevance = $qc->{relevance};
        if (exists $qc->{intro} && $qc->{intro}) {
            foreach my $intro ($qc->{intro}->@*) {
                push @questions, {
                    type       => 'displaytext',
                    style      => 'normal',
                    content    => $intro->{text},
                    _relevance => $relevance,
                };
            }
        }

        if ($qc->{type} eq 'yesno') {
            push @questions, {
                type       => 'yesno',
                content    => $qc->{question},
                ref        => 'YN' . $qc->{id},
                _relevance => $relevance,
                _code      => $qc->{code},
            };
        }
        elsif ($qc->{type} eq 'text') {
            push @questions, {
                type       => 'text',
                content    => $qc->{question},
                ref        => 'FT' . $qc->{id},
                _relevance => $relevance,
                _code      => $qc->{code},
            };
        }
        elsif ($qc->{type} eq 'yesnogroup') {

            push @questions, {
                type       => 'displaytext',
                style      => 'normal',
                content    => $qc->{question},
                _relevance => $relevance,
            };

            my $counter = 1;
            foreach my $subq ($qc->{yesnogroup}->@*) {
                next unless $subq->{Status};
                $counter++;

                push @questions, {
                    type       => 'yesno',
                    content    => $subq->{question},
                    ref        => 'YN' . $qc->{id} . '_' . $counter,
                    _code      => $qc->{code},
                    _relevance => $relevance,
                    _sub       => {
                        ref  => $qc->{code} . '_' . $subq->{referencia},
                        p2a  => $subq->{power2answer},
                        code => $qc->{code}
                    },

                };

            }

        }
        elsif ($qc->{type} eq 'skillset') {
            my $skills = $c->directus->search(
                table => 'skills',
                form  => {
                    'status' => 'published',
                    'sort'   => 'sort,id',
                }
            );

            my $ref = {
                type       => 'multiplechoices',
                content    => $qc->{question},
                ref        => 'MC' . $qc->{id},
                _code      => $qc->{code},
                _relevance => $relevance,
                options    => [],
            };

            my $counter = 0;
            foreach my $skill ($skills->{data}->@*) {
                $ref->{_skills}{$counter} = $skill->{id};
                push @{$ref->{options}}, {
                    display => $skill->{skill},
                    index   => $counter,
                };
                $counter++;
            }

            push @questions, $ref;

        }
        elsif ($qc->{type} eq 'autocontinue') {

            push @questions, {
                type          => 'displaytext',
                style         => 'normal',
                content       => $qc->{question},
                _autocontinue => 1,
                _relevance    => $relevance,
            } if $qc->{question} ne 'autocontinue';

        }
        elsif ($qc->{type} =~ /^botao_/) {
            my $button_title = {
                botao_tela_modo_camuflado => 'Ver',
                botao_tela_socorro        => 'Ver',
            };

            push @questions, {
                type       => 'button',
                content    => $qc->{question},
                _relevance => $relevance,
                action     => $qc->{type},
                ref        => 'BT' . $qc->{id},
                label      => $button_title->{$qc->{type}} || 'Ver',
                _code      => $qc->{code},
            };

        }

    }

    use DDP;
    p \@questions;

    # verificando se o banco nao tem nada muito inconsistente
    my $dup_by_code = {};
    foreach my $qq (@questions) {

        sub is_power_of_two { not $_[0] & $_[0] - 1 }

        die "%s is missing _relevance", to_json($qq) if !$qq->{_relevance};

        if ($qq->{type} eq 'button') {
            for my $missing (qw/content action label ref/) {
                die sprintf "question %s is missing $missing\n", to_json($qq), $missing if !$qq->{$missing};
            }
        }
        elsif ($qq->{type} eq 'multiplechoices') {
            for my $missing (qw/options ref/) {
                die sprintf "question %s is missing $missing\n", to_json($qq), $missing if !$qq->{$missing};
            }

            for my $option ($qq->{options}->@*) {
                die sprintf "question option is missing text\n", to_json($qq) if !$option->{display};
            }

        }
        elsif (exists $qq->{_sub}) {
            for my $missing (qw/content ref/) {
                die sprintf "question %s is missing $missing\n", to_json($qq) if !$qq->{$missing};
            }

            # nao pode ter por exemplo, dois campos referencia ou power2answer iguais na mesma ref
            $dup_by_code->{$qq->{_sub}{code}} ||= {};
            my $dup = $dup_by_code->{$qq->{_sub}{code}};

            if ($dup->{'_' . $qq->{_sub}{ref}}++ > 0) {
                die sprintf "question %s has duplicate reference '%s'\n", to_json($qq), $qq->{_sub}{ref};
            }

            if ($qq->{_sub}{p2a} < 1 || !is_power_of_two($qq->{_sub}{p2a})) {
                die sprintf "question %s has invalid power of two (%s is not a valid value)\n", to_json($qq),
                  $qq->{_sub}{p2a};
            }

            if ($dup->{$qq->{_sub}{p2a}}++ > 0) {
                die sprintf "question %s has duplicate power of two(%s)\n", to_json($qq), $qq->{_sub}{p2a};
            }
        }

    }

    my $stash = {
        pending   => \@questions,
        prev_msgs => []
    };

    return $stash;
}

sub _get_error_questionnaire_stash {
    my ($err, $c) = @_;

    my $stash = {
        prev_msgs => [],
        pending   => [
            &_new_displaytext('Encontramos um problema para montar o questionário!'),
            &_new_displaytext($err . ''),
            {
                type       => 'button',
                content    => 'Tente novamente mais tarde, e entre em contato caso o erro persista.',
                _relevance => '1',
                _reset     => 1,
                ref        => 'btn',
                action     => 'reload',
                label      => 'Tentar agora',
            }
        ]
    };

}

1;
