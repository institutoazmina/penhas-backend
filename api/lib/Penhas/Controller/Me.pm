package Penhas::Controller::Me;
use Mojo::Base 'Penhas::Controller';

use DateTime;

sub check_and_load {
    my $c = shift;

    die 'missing user_id' unless $c->stash('user_id');
    my $user = $c->directus->search_one(
        table => 'clientes',
        form  => {
            'filter[id][eq]'     => $c->stash('user_id'),
            'filter[status][eq]' => 'active',
        }
    );

    $c->reply_not_found() unless $user;
    $c->stash('user' => $user);
    return 1;
}

sub find {
    my $c = shift;

    my %extra;
    my $user = $c->stash('user');
    my $mastodon_session;

    my @modules;
    my $feminino = $user->{genero} eq 'Feminino' || $user->{genero} eq 'FemininoTrans';

    if ($feminino) {
        $mastodon_session = $c->schema->resultset('OauthAccessToken')->find($c->stash('mastodon_oauth_id'));
        $mastodon_session = $mastodon_session->token if $mastodon_session;

        push @modules, qw/timeline chat_privado chat_suporte noticias modo_camuflado modo_anonimo pontos_de_apoio/;
    }
    else {
        push @modules, qw/chat_suporte noticias/;
    }

    my $quiz_session = $c->user_get_quiz_session(user => $user);

    if ($quiz_session) {

        # remove acesso a tudo, o usuario deve completar o quiz
        @modules = qw/quiz/;

        $c->load_quiz_session(session => $quiz_session, user => $user);

        $extra{quiz_session} = $c->stash('quiz_session');

    }

    return $c->render(
        json => {
            user_profile => {
                (
                    map { $_ => $user->{$_} }
                      (qw/email cep dt_nasc nome_completo genero minibio raca cpf_prefix nome_social/)
                ),
            },

            modo_camuflado_ativo         => $user->{modo_camuflado_ativo}         ? 1 : 0,
            modo_anonimo_ativo           => $user->{modo_anonimo_ativo}           ? 1 : 0,
            ja_foi_vitima_de_violencia   => $user->{modo_anonimo_ativo}           ? 1 : 0,
            esta_em_situcao_de_violencia => $user->{esta_em_situcao_de_violencia} ? 1 : 0,
            mastodon_username            => $user->{mastodon_username},
            senha_falsa_sha256           => $user->{senha_falsa_sha256},


            mastodon_session => $mastodon_session,

            modules => \@modules,
            %extra
        },
        status => 200,
    );
}

sub update {
    my $c = shift;


#    return $c->render(json => {id => $user->id}, status => 202,);
}


sub inc_senha_falsa_counter {
    my $c = shift;

    my $user = $c->stash('user');
    $c->directus->update(
        table => 'clientes',
        id    => $user->{id},
        form  => {
            qtde_login_senha_falsa => $user->{qtde_login_senha_falsa} + 1,
        }
    );

    return $c->render(text => '', status => 204,);
}

1;
