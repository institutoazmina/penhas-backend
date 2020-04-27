package Penhas::Helpers::Quiz;
use common::sense;
use Penhas::Directus;
use Carp qw/croak/;
use Penhas::Utils qw/tt_test_condition/;

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
                            'filter[questionnaire_id][eq]' => $id
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

            # tem algum quiz true, entao vamos remover os que o usuario ja completou
            if (@available_quiz) {

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
                foreach my $q (sort { $a->{name} cmp $b->{name} } $c->stash('questionnaires')->@*) {

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

                        $session = $c->directus->create(
                            table => 'clientes_quiz_session',
                            form  => {
                                cliente_id       => $user->{id},
                                questionnaire_id => $q->{id},
                                stash            => &_init_questionnaire_stash($q),
                                responses        => []
                            }
                        );

                    }

                    use DDP;
                    p $session;

                    last;
                }

            }

            use DDP;
            p @available_quiz;

        }
    );


}

sub _init_questionnaire_stash {
    my $questionnaire = shift;

    use DDP; p $questionnaire;

    return {"a","aasd"};
}

1;
