package Penhas::Helpers::Quiz;
use common::sense;
use Carp qw/croak/;
use Digest::MD5 qw/md5_hex/;
use Penhas::Utils qw/tt_test_condition tt_render is_test/;
use JSON;
use utf8;
use warnings;
use Readonly;
use DateTime;
use Penhas::Logger;
use Scope::OnExit;

# a chave do cache é composta por horarios de modificações do quiz_config e questionnaires
use Penhas::KeyValueStorage;

sub _new_displaytext_error {
    {
        type       => 'displaytext',
        content    => $_[0],
        style      => 'error',
        _relevance => '1',
    }
}

sub _new_displaytext_normal {
    {
        type       => 'displaytext',
        content    => $_[0],
        style      => 'normal',
        _relevance => '1',
    }
}

sub _skip_empty_msg {
    my ($question) = @_;
    return exists $question->{content} && $question->{type} ne 'button' ? $question->{content} ? 1 : 0 : 1;
}

sub setup {
    my ($self, %opts) = @_;


    $self->helper('ensure_questionnaires_loaded' => sub { &ensure_questionnaires_loaded(@_) });
    $self->helper('load_quiz_config'             => sub { &load_quiz_config(@_) });
    $self->helper('user_get_quiz_session'        => sub { &user_get_quiz_session(@_) });
    $self->helper('load_quiz_session'            => sub { &load_quiz_session(@_) });
    $self->helper('process_quiz_session'         => sub { &process_quiz_session(@_) });
    $self->helper('process_quiz_assistant'       => sub { &process_quiz_assistant(@_) });
    $self->helper('process_cep_address_lookup'   => sub { &process_cep_address_lookup(@_) });
}

sub ensure_questionnaires_loaded {
    my ($c, %opts) = @_;

    return 1 if $c->stash('questionnaires');

    my $questionnaires = [
        $c->schema2->resultset('Questionnaire')->search(
            {
                (
                    $ENV{FILTER_QUESTIONNAIRE_IDS}
                    ? ('me.id' => {in => [split ',', $ENV{FILTER_QUESTIONNAIRE_IDS}]})
                    : ('me.active' => '1')
                ),
                (
                    $opts{penhas}
                    ? ('me.penhas_start_automatically' => 1)
                    : ('me.penhas_cliente_required' => 0),
                )
            },
            {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
        )->all
    ];
    foreach my $q (@{$questionnaires}) {
        $q->{quiz_config}
          = $c->load_quiz_config(questionnaire_id => $q->{id}, cachekey => $q->{modified_on});
    }
    $c->stash(questionnaires => $questionnaires);
}

sub load_quiz_config {
    my ($c, %opts) = @_;

    my $id       = $opts{questionnaire_id};
    my $kv       = Penhas::KeyValueStorage->instance;
    my $cachekey = "QuizConfig:$id:" . $opts{cachekey};

    #Readonly::Array my @config => @{
    my @config = @{
        $kv->redis_get_cached_or_execute(
            $cachekey,
            86400 * 7,    # 7 days
            sub {
                return [
                    map {
                        $_->{yesnogroup} and $_->{yesnogroup} = from_json($_->{yesnogroup});
                        $_->{intro}      and $_->{intro}      = from_json($_->{intro});
                        $_->{options}    and $_->{options}    = from_json($_->{options});
                        $_
                    } $c->schema2->resultset('QuizConfig')->search(
                        {
                            'status'           => 'published',
                            'questionnaire_id' => $id,

                        },
                        {

                            order_by     => ['sort', 'id'],
                            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                        }
                    )->all
                ];

            }
        )
    };

    #use DDP;
    #p \@config;
    return \@config;
}


sub user_get_quiz_session {
    my ($c, %opts) = @_;
    my $user = $opts{user} or croak 'missing user';

    # verifica se o usuário acabou de fazer um login,
    # se sim, ignora o quiz
    my $key = $ENV{REDIS_NS} . 'is_during_login:' . $user->{id};
    return if $c->kv->redis->del($key) && !is_test();

    Log::Log4perl::NDC->push('user_get_quiz_session user_id:' . $user->{id});
    on_scope_exit { Log::Log4perl::NDC->pop };

    $c->ensure_questionnaires_loaded(penhas => 1);

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
    my $rs = $c->schema2->resultset('ClientesQuizSession')->search(
        {
            'deleted_at' => undef,
        }
    );
    my %is_finished = map { $_->{questionnaire_id} => 1 } $rs->search(
        {
            'finished_at'      => {'!=' => undef},
            'cliente_id'       => $user->{id},
            'questionnaire_id' => {'in' => [map { $_->{id} } @available_quiz]},
        },
        {
            # só precisamos deste campo
            'columns'    => ['questionnaire_id'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;

    # esta muito simples por enquanto, vou ordenar pelo nome
    # e deixar apenas um ativo questionario por vez
    foreach my $q (sort { $a->{name} cmp $b->{name} } @available_quiz) {

        Log::Log4perl::NDC->push('questionnaires_id:' . $q->{id});
        on_scope_exit { Log::Log4perl::NDC->pop };

        # pula se ja respondeu tudo
        log_info('is already finished'), next if $is_finished{$q->{id}};

        # procura pela session deste quiz, se nao existir precisamos criar uma
        my $session = $rs->search(
            {
                'cliente_id'       => $user->{id},
                'questionnaire_id' => $q->{id},
            },
            {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
        )->next;
        if (!$session) {
            log_info('Running _init_questionnaire_stash');
            my $stash = eval { &_init_questionnaire_stash($q, $c, 0) };
            if ($@) {
                my $err = $@;
                slog_error('Running _init_questionnaire_stash FAILED: %s', $err);
                die $@ if is_test();

                #use DDP; p $@;
                $stash = &_get_error_questionnaire_stash($err, $c);
            }

            slog_info('Create new session with stash=%s', to_json($stash));

            $session = $rs->create(
                {
                    cliente_id       => $user->{id},
                    questionnaire_id => $q->{id},
                    stash            => to_json($stash),
                    responses        => to_json({start_time => time()}),
                    created_at       => DateTime->now->datetime(' '),
                }
            );
            $session = {$session->get_columns};
            log_trace('clientes_quiz_session:created');
            slog_info('Created session clientes_quiz_session.id:%s', $session->{id});
        }
        else {
            log_trace('clientes_quiz_session:loaded');
            slog_info(
                'Loaded session clientes_quiz_session.id:%s with stash=%s', $session->{id},
                $session->{stash}
            );
        }

        $session->{stash}     = from_json($session->{stash});
        $session->{responses} = from_json($session->{responses});

        return $session;
    }

    # todos os quiz estao finished
    return;

}

sub _quiz_get_vars {
    my ($user, $responses) = @_;

    #use DDP;
    #p [$user, $responses];
    return {cliente => $user, %{$responses || {}}};
}

sub load_quiz_session {
    my ($c, %opts) = @_;

    $opts{caller_is_post} ||= 0;

    my $session_rs = 'ClientesQuizSession';
    my $user       = $opts{user};
    my $is_anon    = $opts{is_anon} ? 1 : 0;

    croak 'missing user' if !$is_anon && !$user;

    if ($is_anon) {
        $session_rs = 'AnonymousQuizSession';
        $user       = {};
    }

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
    my $loop_detection = 100;
  ADD_QUESTIONS:
    log_debug("loop_detection=$loop_detection");
    if (--$loop_detection < 0) {
        $c->stash(
            quiz_session => {
                session_id   => $session->{id},
                current_msgs => [&_new_displaytext_error('Loop no quiz detectado, entre em contato com o suporte')],
                prev_msgs    => $stash->{prev_msgs}
            }
        );
        return;
    }

    my @frontend_msg;

    # nao tem nenhuma relevante pro usuario, pegar todas as pending ate um input
    if ($add_more_questions) {

        my $is_last_item = 0;
        do {
            my $item = shift $stash->{pending}->@*;
            if ($item) {
                log_info("Maybe adding question " . to_json($item));

                my $has = &has_relevance($vars, $item);
                slog_info(
                    '  Testing question relevance %s "%s" %s',
                    $has ? '✔️ True ' : '❌ False',
                    (exists $item->{_sub} && exists $item->{_sub}{ref} ? $item->{_sub}{ref} : $item->{content}),
                    $item->{_relevance},
                );

                # pegamos um item que eh input, entao vamos sair do loop nesta vez
                $is_last_item = 1 if $item->{type} ne 'displaytext';

                if (!$has) {
                    log_info("question is not relevant, testing next question...");
                    $is_last_item = 0;
                }

                # joga item pra lista de msg correntes
                push $current_msgs->@*, $item;

            }
            else {
                $is_last_item = 1;
            }

            log_info("LAST_ITEM=$is_last_item");

            $update_db++;
        } while !$is_last_item;

        # chegamos no final do chat
        if ($stash->{pending}->@* == 0) {
            log_info("set is_eof to 1");
            $stash->{is_eof} = 1;
            $update_db++;
        }
    }

    slog_info('vars %s', to_json($vars));

    foreach my $q ($current_msgs->@*) {
        my $has = &has_relevance($vars, $q);
        $q->{_currently_has_relevance} = $has;
        slog_info(
            'Rendering: question relevance %s "%s" %s',
            $has ? '✔️ True' : '❌ False',
            (exists $q->{_sub} && exists $q->{_sub}{ref} ? $q->{_sub}{ref} : $q->{content}),
            $q->{_relevance},
        );

        if ($has) {
            push @frontend_msg, $q;
        }
    }

    # nao teve nenhuma relevante, adiciona mais questoes,
    # mesmo se tiver um botao agora que nao esta visivel
    # isso faz com que seja possível desenhar um fluxo onde uma pergunta no futuro
    # muda reativa a visibilidade de uma pergunta do passado
    # embora isso possa ser uma bad-pratice, pois isso pode fazer com que
    # a pergunta atual do 'nada' fique com dois inputs, caso mal feita a logica
    # ja que essa situacao nao esta testada no app.
    if (!@frontend_msg) {
        log_info("⚠️ No frontend questions found... current_msgs is " . to_json($current_msgs));

        if (!$stash->{is_eof}) {
            log_info("🔁 is_eof=0, GOTO ADD_QUESTIONS ");
            $add_more_questions = 1;

            goto ADD_QUESTIONS;
        }
        else {
            log_info("is_eof=1  caller_is_post=" . $opts{caller_is_post});
            if (!$opts{caller_is_post}) {

              ADD_BTN_FIM:
                log_info("🔴 Adding generic END button");

                # acabou sem um input [pois isso aqui eh chamado no GET],
                # vou colocar um input padrao de finalizar
                $current_msgs = [
                    {
                        type       => 'button',
                        content    => 'Tudo certo por aqui! Recado para administrador: quiz acabou sem botão fim!',
                        action     => '',
                        ref        => 'BT_END_' . int(rand(100000)),
                        label      => 'Finalizar',
                        _relevance => '1',
                        _code      => 'FORCED_END_CHAT',
                        _end_chat  => 1,
                        _currently_has_relevance => 1,
                    }
                ];
                $stash->{is_eof}++;
                $update_db++;
            }
            else {
                if (!$stash->{is_finished}) {
                    log_info("😟 forcing add-button");
                    goto ADD_BTN_FIM;
                }
                else {
                    log_info("🉑 quiz finished, bye bye!");
                }
            }
        }

    }

    $stash->{current_msgs} = $current_msgs;

    # se teve modificações, entamos vamos escrever a stash de volta no banco
    # isso eh necessario pois o metodo que o metodo que receba as respostas nao precise "renderizar" o chat
    # [chamar propria rotina]
    # e tambem para evitar que ele avance o chat ou receber uma resposta sem sentido mas avançar o chat
    if ($update_db) {

        slog_info('updating %s stash to %s',     $session_rs, to_json($stash));
        slog_info('updating %s responses to %s', $session_rs, to_json($responses));

        my $rs = $c->schema2->resultset($session_rs);
        $rs->search({id => $session->{id}})->update(
            {
                stash     => to_json($stash),
                responses => to_json($responses),
                (
                    $stash->{is_finished}
                    ? (finished_at => DateTime->now->datetime(' '))
                    : ()
                )
            }
        );
    }

    if (exists $stash->{is_finished} && $stash->{is_finished}) {

        my $end_screen = '';
        $c->ensure_questionnaires_loaded(penhas => $is_anon ? 0 : 1);
        foreach my $q ($c->stash('questionnaires')->@*) {
            next unless $q->{id} == $session->{questionnaire_id};
            $end_screen = $q->{end_screen};
            last;
        }

        $c->stash(
            'quiz_session' => {
                finished   => 1,
                end_screen => tt_render($end_screen, $vars),
            }
        );
    }
    else {
        my @real_frontend_msg;
        foreach my $q (@frontend_msg) {
            if (exists $q->{_show_cep_results}) {

                $q->{type} = 'displaytext';

                if ($vars->{cep_results}) {

                    $q->{content} = 'Este são os resultados que encontrei para [% human_address %]';
                    my $render = &_render_question($q, $vars);
                    push @real_frontend_msg, $render;

                    foreach my $current_line (@{from_json($vars->{cep_results})}) {
                        $q->{content} = $current_line;
                        my $render = &_render_question($q, $vars);
                        push @real_frontend_msg, $render;
                    }
                }
                else {
                    $q->{content} = 'erro: faltando cep_results';
                }
            }
            else {
                push @real_frontend_msg, &_render_question($q, $vars);
            }
        }

        $c->stash(
            'quiz_session' => {
                current_msgs => [grep { &_skip_empty_msg($_) } @preprend_msg, @real_frontend_msg],
                session_id   => $session->{id},
                prev_msgs    => $opts{caller_is_post}
                ? undef
                : [
                    grep { &_skip_empty_msg($_) }
                    map  { &_render_question($_, $vars) } $stash->{prev_msgs}->@*
                ],
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

sub process_quiz_assistant {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj}      or croak 'missing user_obj';
    my $params   = delete $opts{params} or croak 'missing params';


    log_info("process_quiz_assistant " . to_json($params));

    my $user = {$user_obj->get_columns};
    my @preprend_msg;

    if (exists $params->{reset_questionnaire}) {
        if ($params->{reset_questionnaire} eq 'Y') {

            $user_obj->reset_all_questionnaires();

            my $quiz_session = $c->user_get_quiz_session(user => $user);
            if ($quiz_session) {

                $c->load_quiz_session(session => $quiz_session, user => $user);
                return {quiz_session => $c->stash('quiz_session')};
            }
            else {
                push @preprend_msg, &_new_displaytext_normal('Não há questionários para você no momento!');
            }
        }
        elsif ($params->{reset_questionnaire} eq 'N') {

            push @preprend_msg, {
                type       => 'button',
                content    => 'Tudo bem, no momento esta é minha única função!',
                action     => '',
                ref        => 'BT_RETURN',
                label      => 'Retornar',
                _relevance => '1',
            };
        }
        else {
            push @preprend_msg, &_new_displaytext_error('Valor para reset_questionnaire precisa ser Y ou N');
        }
    }
    elsif (exists $params->{BT_RETURN} && $params->{BT_RETURN} eq '1') {
        return {
            quiz_session => {
                finished   => 1,
                end_screen => '/mainboard?page=chat',
            }
        };
    }
    else {
        push @preprend_msg, &_new_displaytext_error('Não entendo outros campos.');
    }

    return {
        quiz_session => {
            session_id   => $user_obj->assistant_session_id(),
            current_msgs => [map { &_render_question($_, $user) } @preprend_msg],
            prev_msgs    => undef,
        }
    };
}

sub process_quiz_session {
    my ($c, %opts) = @_;

    my $is_anon = $opts{is_anon};
    my $user;
    my $user_obj;

    if (!$is_anon) {
        $user     = $opts{user}     or croak 'missing user';
        $user_obj = $opts{user_obj} or croak 'missing user_obj';
    }
    else {
        $user = {};
    }

    my $session = $opts{session}       or croak 'missing session';
    my $params  = delete $opts{params} or croak 'missing params';

    log_info("process_quiz_session " . to_json($params));

    my $stash        = $session->{stash};
    my $current_msgs = $stash->{current_msgs} || [];
    my $responses    = $session->{responses};

    my @preprend_msg;

    my $set_modo_camuflado;
    my $update_user_skills;
    my $have_new_responses = 0;
    log_info("testing reverse... order of messages.." . to_json($current_msgs));
  QUESTIONS:
    foreach my $msg (reverse $current_msgs->@*) {

        # se ela nao tava na tela, nao podemos processar as respostas
        next unless $msg->{_currently_has_relevance};

        my $ref = $msg->{ref};
        next unless $ref;

        log_info("ref=$ref?");
        if (exists $params->{$ref}) {
            my $val = defined $params->{$ref} ? $params->{$ref} : '';
            log_info("Found, $ref=$val");
            my $code = $msg->{_code};
            die sprintf "missing `_code` on message %s", to_json($msg) unless $code;

            log_info("msg type " . $msg->{type});

            if ($msg->{type} eq 'yesno') {

                if ($val =~ /^(Y|N)$/) {

                    # processa a questao que o cadastro (code) eh unico
                    # mas esta espalhada em varias mensagens
                    if (exists $msg->{_sub}) {
                        $responses->{$msg->{_sub}{ref}} = $val;

                        if (exists $responses->{$code}) {
                            if ($responses->{$code} !~ /^\d+/) {
                                push @preprend_msg,
                                  &_new_displaytext_error(
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
                            if ($val eq 'Y') {
                                $responses->{$code} = $msg->{_sub}{p2a};
                            }
                            else {
                                # inicia como '0'
                                $responses->{$code} = 0;
                            }

                        }

                        $code = $msg->{_sub}{code} . '_' . $msg->{_sub}{p2a};
                    }

                    $responses->{$code} = $val;
                    $msg->{display_response} = $val eq 'Y' ? 'Sim' : 'Não';
                    $have_new_responses++;
                }
                else {
                    push @preprend_msg, &_new_displaytext_error(sprintf('Campo %s deve ser Y ou N', $ref));
                }
            }
            elsif ($msg->{type} eq 'text') {

                if ($msg->{_cep_address_lookup}) {
                    my ($update, $preprend) = $c->process_cep_address_lookup(
                        msg       => $msg,
                        responses => $responses,
                        value     => $val,
                        code      => $code,
                    );

                    if ($update) {
                        $have_new_responses++;
                    }
                    else {
                        push @preprend_msg, @$preprend;
                    }

                }
                else {
                    $responses->{$code} = $val;
                    $msg->{display_response} = $val;
                    $have_new_responses++;
                }
            }
            elsif ($msg->{type} eq 'multiplechoices') {

                # lista de ate 999 numeros
                if (defined $val && length $val <= 6000 && $val =~ /^[0-9]{1,6}(?>,[0-9]{1,6})*$/a) {

                    my $reverse_index = {map { $_->{index} => $_->{display} } $msg->{options}->@*};
                    my $output        = '';
                    my $output_human  = '';
                    foreach my $index (split /,/, $val) {

                        # pula caso venha opcoes invalidas
                        next unless defined $reverse_index->{$index};

                        $output_human .= $reverse_index->{$index} . ', ';
                        $output       .= $index . ',';

                        if (exists $msg->{_skills}) {
                            $update_user_skills = {} unless defined $update_user_skills;
                            my $id = ref $msg->{_skills} eq 'ARRAY' ? $msg->{_skills}[$index] : $msg->{_skills}{$index};
                            log_info("skill ref is " . ref $msg->{_skills});
                            $update_user_skills->{set}{$id} = 1;
                        }
                    }
                    chop($output_human);    # rm espaco
                    chop($output_human);    # rm virgula
                    chop($output);          # rm virgula

                    $responses->{$code} = '[' . $output . ']';
                    $msg->{display_response} = $output_human;
                    $have_new_responses++;

                }
                else {
                    push @preprend_msg, &_new_displaytext_error(sprintf('Campo %s deve uma lista de números', $ref));
                }

            }
            elsif ($msg->{type} eq 'onlychoice') {

                # index de ate 999999
                if (defined $val && length $val <= 6 && $val =~ /^[0-9]+$/a && defined $msg->{_db_option}[$val]) {

                    my $reverse_index = {map { $_->{index} => $_->{display} } $msg->{options}->@*};

                    my $output_human = $reverse_index->{$val};
                    my $output       = $msg->{_db_option}[$val];

                    $responses->{$code} = $output;
                    $msg->{display_response} = $output_human;
                    $have_new_responses++;

                }
                else {
                    push @preprend_msg, &_new_displaytext_error(sprintf('Campo %s deve um número', $ref));
                }

            }
            elsif ($msg->{type} eq 'button') {

                log_info("msg type button");

                # reiniciar o fluxo
                if ($msg->{_reset}) {
                    $c->ensure_questionnaires_loaded(penhas => 1);
                    foreach my $q ($c->stash('questionnaires')->@*) {
                        next unless $q->{id} == $session->{questionnaire_id};
                        $stash     = &_init_questionnaire_stash($q, $c, $is_anon);
                        $responses = {start_time => time()};
                        $have_new_responses++;
                        last;
                    }
                }
                else {
                    $responses->{$code}             = $val;
                    $responses->{$code . '_action'} = $msg->{action};
                    $msg->{display_response}        = $msg->{label};
                    $have_new_responses++;

                    if ($msg->{action} eq 'botao_tela_modo_camuflado') {
                        $set_modo_camuflado = $val;
                    }

                    if ($stash->{is_eof} || $msg->{_end_chat}) {
                        $stash->{is_finished} = 1;
                    }
                }

            }
            else {
                push @preprend_msg, &_new_displaytext_error(sprintf('typo %s não foi programado!', $msg->{type}));
            }

        }
        else {
            push @preprend_msg, &_new_displaytext_error(sprintf('Campo %s nao foi enviado', $ref));
        }

        # vai embora, pois so devemos ter 1 resposta por vez
        # pelo menos eh assim que eu imagino o uso por enquanto
        last QUESTIONS if $have_new_responses;
    }

    log_info("have_new_responses=$have_new_responses");

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
        if ($user_obj && defined $update_user_skills->{set}) {
            $c->cliente_set_skill(user => $user, skills => [keys $update_user_skills->{set}->%*]);
        }

        if ($user_obj && defined $set_modo_camuflado) {

            # se for 1, eh pra ativar
            # sefor 0, nao ativa, mas precisa manter ligar o do mesmo jeito anonimo
            $user_obj->cliente_modo_camuflado_toggle(active => $set_modo_camuflado eq '1' ? 1 : 0);
            $user_obj->cliente_modo_anonimo_toggle(active => 1);
            $user_obj->quiz_detectou_violencia_toggle(active => 1);
        }
        elsif ($user_obj) {

            # atualmente só tem um quiz no Penhas, por isso seta pra falso quando nao estiver defined
            # o melhor será criar um campo 'type' no questionnaire pra saber qual
            $user_obj->quiz_detectou_violencia_toggle(active => 0);
        }

    }

    $c->load_quiz_session(
        %opts,
        preprend_msg   => \@preprend_msg,
        caller_is_post => 1,
    );

}


sub has_relevance {
    my ($vars, $msg) = @_;

    return 1                     if $msg->{_relevance} eq '1';
    die '_self already exists!!' if exists $vars->{_self};
    use DDP;
    p $msg;
    local $vars->{_self} = $msg->{_code};
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
    my $is_anon       = shift;

    die "AnError\n" if exists $ENV{DIE_ON_QUIZ};

    my @questions;
    foreach my $qc ($questionnaire->{quiz_config}->@*) {

        my $relevance = $qc->{relevance};
        if (exists $qc->{intro} && $qc->{intro}) {
            foreach my $intro ($qc->{intro}->@*) {
                push @questions, {
                    type       => 'displaytext',
                    style      => 'normal',
                    content    => '[' . $qc->{code} . '] '. $intro->{text},
                    _code      => $qc->{code},
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
                ($is_anon ? (code => $qc->{code}) : ()),
            };
        }
        elsif ($qc->{type} eq 'text') {
            push @questions, {
                type       => 'text',
                content    => $qc->{question},
                ref        => 'FT' . $qc->{id},
                _relevance => $relevance,
                _code      => $qc->{code},
                ($is_anon ? (code => $qc->{code}) : ()),
            };
        }
        elsif ($qc->{type} eq 'yesnogroup') {

            my $counter = 1;
            foreach my $subq ($qc->{yesnogroup}->@*) {
                next unless $subq->{Status};
                $counter++;

                push @questions, {
                    type    => 'yesno',
                    content => $subq->{question},
                    ref     => 'YN' . $qc->{id} . '_' . $counter,
                    _code   => $qc->{code},
                    ($is_anon ? (code => $qc->{code} . '_' . $subq->{referencia}) : ()),
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
            my $skills = [
                $c->schema2->resultset('Skill')->search(
                    {
                        'status' => 'published',
                    },
                    {
                        order_by     => ['sort', 'id'],
                        result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                    }
                )->all
            ];
            my $ref = {
                type    => 'multiplechoices',
                content => $qc->{question},
                ref     => 'MC' . $qc->{id},
                _code   => $qc->{code},
                ($is_anon ? (code => $qc->{code}) : ()),
                _relevance => $relevance,
                options    => [],
            };

            my $counter = 0;
            foreach my $skill ($skills->@*) {
                $ref->{_skills}{$counter} = $skill->{id};
                push @{$ref->{options}}, {
                    display => $skill->{skill},
                    index   => "$counter",        # manter como string, garantido, pq se nao quebra o parser do app
                };
                $counter++;
            }

            push @questions, $ref;

        }
        elsif ($qc->{type} eq 'displaytext') {

            push @questions, {
                type       => 'displaytext',
                style      => 'normal',
                content    => '[' . $qc->{code} . '] '. $qc->{question},
                _relevance => $relevance,
                ($is_anon ? (code => $qc->{code}) : ()),
            };

        }
        elsif ($qc->{type} eq 'botao_tela_modo_camuflado') {
            my $button_title = {
                botao_tela_modo_camuflado => 'Explicação do Modo Camuflado',
                botao_fim                 => 'Finalizar'
            };

            push @questions, {
                type               => 'button',
                content            => $qc->{question},
                action             => 'botao_tela_modo_camuflado',
                ending_cancel_text => 'Tutorial cancelado',
                ending_action_text => 'Modo camuflado ativado',
                ref                => 'BT' . $qc->{id},
                label              => $qc->{button_label} || 'Visualizar',
                _relevance         => $relevance,
                _code              => $qc->{code},
                ($is_anon ? (code => $qc->{code}) : ()),
            };

        }
        elsif ($qc->{type} eq 'botao_fim') {

            push @questions, {
                type       => 'button',
                content    => '[' . $qc->{code} . '] '. $qc->{question},
                action     => 'none',
                ref        => 'BT' . $qc->{id},
                label      => $qc->{button_label} || 'Enviar',
                _relevance => $relevance,
                _code      => $qc->{code},
                ($is_anon ? (code => $qc->{code}) : ()),
                _end_chat => 1,
            };

        }
        elsif ($qc->{type} eq 'onlychoice') {

            my $ref = {
                type    => 'onlychoice',
                content => '[' . $qc->{code} . '] '.$qc->{question},
                ref     => 'OC' . $qc->{id},
                _code   => $qc->{code},
                ($is_anon ? (code => $qc->{code}) : ()),
                _relevance => $relevance,
                options    => [],
            };

            my $counter = 0;
            foreach my $option ($qc->{options}->@*) {
                my $value = $option->{value};
                $value =~ s/\,/\\\,/;
                $ref->{_db_option}[$counter] = $value;

                push @{$ref->{options}}, {
                    display => $option->{label},
                    index   => $counter,
                    ($is_anon ? (code_value => $value) : ()),
                };
                $counter++;
            }
            push @questions, $ref;

        }
        elsif ($qc->{type} eq 'cep_address_lookup') {
            push @questions, {
                type                => 'text',
                _cep_address_lookup => 1,
                content             => '[' . $qc->{code} . '] '. $qc->{question},
                ref                 => 'CEP' . $qc->{id},
                _relevance          => $relevance,
                _code               => $qc->{code},
                ($is_anon ? (code => $qc->{code}) : ()),
            };
            push @questions, {
                type              => 'displaytext',
                _show_cep_results => 1,
                _relevance        => $relevance,
                _code             => $qc->{code} . '_show_results',
                ($is_anon ? (code => $qc->{code}) : ()),
            };
        }
        else {
            die sprintf 'FATAL ERROR: question type "%s" is not supported!\n', $qc->{type};
        }

    }

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
            &_new_displaytext_error('Encontramos um problema para montar o questionário!'),
            &_new_displaytext_error($err . ''),
            {
                type                     => 'button',
                content                  => 'Tente novamente mais tarde, e entre em contato caso o erro persista.',
                _relevance               => '1',
                _currently_has_relevance => 1,
                _reset                   => 1,
                _code                    => 'ERROR',
                ref                      => 'btn',
                action                   => 'reload',
                label                    => 'Tentar agora',
            }
        ]
    };

}

sub process_cep_address_lookup {
    my ($c, %opts) = @_;

    my $responses = $opts{responses};
    my $code      = $opts{code};

    my ($success, $preprend) = (0, []);

    my $help  = 'Digite novamente no formato 00000-000 ou escreva "Sair" para desistir.';
    my $value = $opts{value} // '';

    log_debug("process_cep_address_lookup: $value");
    $value =~ s/[^0-9]//g;

    if ($value eq '') {

        push @$preprend, &_new_displaytext_error("Não encontrei os dígitos para buscar o CEP! $help");

        goto RETURN;
    }
    elsif (length($value) < 8) {

        push @$preprend,
          &_new_displaytext_error("Não encontrei dígitos suficiente para começar uma buscar pelo CEP! $help");

        goto RETURN;
    }
    elsif (length($value) > 8) {

        push @$preprend, &_new_displaytext_error("Encontrei dígitos demais para buscar o CEP! $help");

        goto RETURN;
    }

    my $latlng = $c->geo_code_cached($value);
    my ($lat, $lng) = split /,/, $latlng;
    if (!$latlng) {
        my $cep_fmt = join '-', substr($value, 0, 5), substr($value, 5, 3);
        push @$preprend,
          &_new_displaytext_error(
            sprintf 'Não encontrei a rua do CEP %s! O CEP precisa estar localizado no Brasil.',
            $cep_fmt
          );
        goto RETURN;
    }

    my $label = $c->reverse_geo_code_cached($latlng);
    if (!$label) {
        $label = "a latitude $lat e longitude $lng";
    }
    $responses->{human_address} = $label;
    $responses->{latlng}        = $latlng;

    my ($success_ponto, $json) = $c->anon_ponto_apoio_json(
        latitude  => $lat,
        longitude => $lng,
    );

    if (!$success_ponto) {
        push @$preprend,
          &_new_displaytext_error(
            sprintf
              'Não encontrei serviço de atendimento num raio de 50 km de %s! Digite outro cep our "Sair" para acabar a conversa',
            $label
          );
        goto RETURN;
    }

    $responses->{cep_results} = $json;
    $responses->{$code} = $value;

    $success = 1;

  RETURN:
    return ($success, $preprend);
}

1;