package Penhas::Helpers::Quiz;
use common::sense;
use Penhas::Directus;
use Carp qw/croak/;
use Penhas::Utils qw/tt_test_condition/;
use JSON;

# TODO cache no redis, receber callback para limpar do redis toda vez que mudar
use Penhas::KeyValueStorage;

sub setup {
    my $self = shift;

    $self->helper(
        'ensure_questionnaires_loaded' => sub {
            my ($c, %opts) = @_;

            return 1 if $c->stash('questionnaires');

            my $questionnaires = $c->directus->search(
                table => 'questionnaires',
                form  => {
                    $ENV{FILTER_QUESTIONNAIRE_IDS}
                    ? ('filter[id][in]' => $ENV{FILTER_QUESTIONNAIRE_IDS})
                    : ('filter[active][eq]' => '1')
                }
            );

            foreach my $q (@{$questionnaires->{data}}) {
                $q->{quiz_config}
                  = $c->load_quiz_config(questionnaire_id => $q->{id}, modified_on => $q->{modified_on});
            }

            $c->stash(questionnaires => $questionnaires->{data});

        }
    );

    $self->helper(
        'load_quiz_config' => sub {
            my ($c, %opts) = @_;

            my $id      = $opts{questionnaire_id};
            my $lastmod = $opts{modified_on};
            my $kv      = Penhas::KeyValueStorage->instance;

            my $cachekey = "QuizConfig:$id:$lastmod";
            my $config   = $kv->redis_get_cached_or_execute(
                $cachekey,
                3600,
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
            );
            return $config;
        }
    );

    $self->helper(
        'user_get_quiz' => sub {
            my ($c, %opts) = @_;
            my $user = $opts{user} or croak 'missing user';

            $c->ensure_questionnaires_loaded();

            my @available_quiz;
            my $vars = {cliente => $user};

            foreach my $q ($c->stash('questionnaires')->@*) {
                if (tt_test_condition($q->{condition}, $vars)) {
                    push @available_quiz, $q;
                }
            }

            return if !@available_quiz;

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

                # pula se ja respondeu tudo
                next if $is_finished{$q->{id}};

                # procura pela session deste quiz, se nao existir precisamos criar uma
                my $session = $c->directus->search_one(
                    table => 'clientes_quiz_session',
                    form  => {
                        'filter[cliente_id][eq]'       => $user->{id},
                        'filter[questionnaire_id][eq]' => $q->{id},
                    }
                );
                if (!$session) {

                    my $stash = eval { &_init_questionnaire_stash($q, $c) };
                    if ($@) {
                        $stash = &_get_error_questionnaire_stash($@, $c);
                    }

                    $session = $c->directus->create(
                        table => 'clientes_quiz_session',
                        form  => {
                            cliente_id       => $user->{id},
                            questionnaire_id => $q->{id},
                            stash            => $stash,
                            responses        => []
                        }
                    );

                }

                use DDP;
                p $session;

                last;
            }

            use DDP;
            p @available_quiz;

        }
    );


}

sub _init_questionnaire_stash {
    my $questionnaire = shift;
    my $c             = shift;

    die "AnError\n" if exists $ENV{DIE_ON_QUIZ};

    my @questions;
    foreach my $qc ($questionnaire->{quiz_config}->@*) {

        my $relevance = $qc->{relevance};

        foreach my $intro ($qc->{intro}->@*) {
            push @questions, {
                type       => 'displaytext',
                content    => $intro->{text},
                _relevance => $relevance,
            };
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
        elsif ($qc->{type} eq 'freetext') {
            push @questions, {
                type       => 'textinput',
                content    => $qc->{question},
                ref        => 'FT' . $qc->{id},
                _relevance => $relevance,
                _code      => $qc->{code},
            };
        }
        elsif ($qc->{type} eq 'yesnogroup') {

            push @questions, {
                type       => 'displaytext',
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
                    _relevance => $relevance,
                    _sub       => {ref => $subq->{referencia}, power2 => $subq->{power2answer}, code => $qc->{code}},

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
                _relevance => $relevance,
            };

            my $counter = 0;
            foreach my $skill ($skills->{data}->@*) {
                $ref->{_mc}{$counter} = $skill->{id};
                push $ref->{options}->@*, {
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
                label      => $button_title,
            };

        }

    }

    # verificando se o banco nao tem nada muito inconsistente
    my $dup_by_code = {};
    foreach my $qq (@questions) {

        sub is_power_of_two { not $_[0] & $_[0] - 1 }

        die "%s is missing _relevance", to_json($qq) if !$qq->{_relevance};

        if ($qq->{type} eq 'button') {
            for my $missing (qw/content action label/) {
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

            if ($qq->{_sub}{power2} < 1 || !is_power_of_two($qq->{_sub}{power2})) {
                die sprintf "question %s has invalid power of two (%s is not a valid value)\n", to_json($qq),
                  $qq->{_sub}{power2};
            }

            if ($dup->{$qq->{_sub}{power2}}++ > 0) {
                die sprintf "question %s has duplicate power of two(%s)\n", to_json($qq), $qq->{_sub}{power2};
            }
        }

    }

    my $stash = {pending => \@questions};

    return $stash;
}

sub _get_error_questionnaire_stash {
    my ($err, $c) = @_;

    my $stash = {
        pending => [
            {
                type       => 'displaytext',
                content    => 'Encontramos um problema para montar o questionário!',
                _relevance => '1'
            },
            {
                type       => 'displaytext',
                content    => $err . '',
                _relevance => '1'
            },
            {
                type    => 'multiplechoices',
                content => 'Tente novamente mais tarde, e entre em contato caso o erro persista.',
                ref     => 'MC_RESET',
                options => [
                    display => 'Tentar novamente',
                    index   => 0
                ]
            }
        ]
    };

}

1;
