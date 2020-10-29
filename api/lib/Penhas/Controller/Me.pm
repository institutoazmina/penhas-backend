package Penhas::Controller::Me;
use Mojo::Base 'Penhas::Controller';
use Carp;
use DateTime;
use JSON;
use Penhas::Types qw/IntList Raca/;
use MooseX::Types::Email qw/EmailAddress/;
use Digest::SHA qw/sha256_hex/;

sub check_and_load {
    my $c = shift;

    die 'missing user_id' unless $c->stash('user_id');
    return 1 if $c->stash('user_obj');

    my $user = $c->schema2->resultset('Cliente')->search(
        {
            'id'           => $c->stash('user_id'),
            'status'       => 'active',
            'login_status' => 'OK',
        },
    )->next;

    $c->reply_not_found() unless $user;
    $c->stash('user_obj' => $user);
    $c->stash('user'     => {$user->get_columns});    # nao pode ser o inflacted
                                                      # MANTER ATUALIZADO EMBAIXO EM "ATUALIZAR AQUI"

    $user->update_activity($c->req->url->path->to_string =~ /timeline/);

    # lazy update
    if (!defined $user->skills_cached) {
        $user->update({skills_cached => to_json([sort map { $_->skill_id() } $user->cliente_skills->all])});
    }

    return 1;
}

sub find {
    my $c = shift;

    my %extra;
    my $user     = $c->stash('user');
    my $user_obj = $c->stash('user_obj');

    my $feminino = $user_obj->is_female;
    my $modules  = $user_obj->access_modules_as_config;

    my $quiz_session = $c->user_get_quiz_session(user => $user);

    if ($quiz_session) {

        # remove acesso a tudo, o usuario deve completar o quiz
        $modules = [
            {
                code => 'quiz',
                meta => {}
            }
        ];

        $c->load_quiz_session(session => $quiz_session, user => $user);

        $extra{quiz_session} = $c->stash('quiz_session');

        $c->log->info(to_json($extra{quiz_session}));
    }

    return $c->render(
        json => {
            user_profile => {
                avatar_url => $user->{avatar_url} || $ENV{AVATAR_PADRAO_URL},

                ja_foi_vitima_de_violencia => $user->{ja_foi_vitima_de_violencia} ? 1 : 0,
                modo_camuflado_ativo       => $user->{modo_camuflado_ativo}       ? 1 : 0,
                modo_anonimo_ativo         => $user->{modo_anonimo_ativo}         ? 1 : 0,
                (
                    map { $_ => $user->{$_} }
                      (qw/email apelido cep dt_nasc nome_completo genero minibio raca cpf_prefix nome_social/)
                ),

                skills => from_json($user->{skills_cached}),
            },

            ($user->{modo_anonimo_ativo} ? (anonymous_avatar_url => $ENV{AVATAR_ANONIMO_URL}) : ()),

            qtde_guardioes_ativos => $user->{qtde_guardioes_ativos},

            modules => $modules,
            %extra
        },
        status => 200,
    );
}

sub update {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');
    my $valid    = $c->validate_request_params(
        skills        => {required   => 0,    type     => IntList, empty_is_valid => 1,},
        skills_remove => {required   => 0,    type     => 'Bool'},
        apelido       => {max_length => 40,   required => 0, type => 'Str', min_length => 2},
        senha_nova    => {max_length => 200,  required => 0, type => 'Str', min_length => 6},
        minibio       => {max_length => 2200, required => 0, type => 'Str'},
        email         => {max_length => 200,  required => 0, type => EmailAddress},
        raca          => {required   => 0,    type     => Raca},
    );

    if ((exists $valid->{email} && $valid->{email}) || (exists $valid->{senha_nova} && $valid->{senha_nova})) {
        my $data = $c->validate_request_params(
            senha_atual => {max_length => 200, required => 1, type => 'Str', min_length => 6},
        );

        my $senha = sha256_hex($data->{senha_atual});
        if (lc($senha) ne lc($user_obj->senha_sha256())) {
            $c->reply_invalid_param('Senha atual não confere.', 'form_error', 'senha_atual');
        }
    }

    $valid->{email} = lc($valid->{email}) if exists $valid->{email};

    if (exists $valid->{senha_nova} && $valid->{senha_nova}) {
        $valid->{senha_sha256} = lc(sha256_hex(delete $valid->{senha_nova}));
    }

    if (delete $valid->{skills_remove}) {
        $valid->{skills} = '';
    }

    my $skills = delete $valid->{skills};
    if (defined $skills) {
        my @skills = split ',', $skills;
        my %valids = map {
            $_->{id} => 1,
        } $c->schema2->resultset('Skill')->search(
            {id => {'in' => \@skills}},
            {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                columns      => ['id']
            }
        )->all;
        foreach (@skills) {
            next if $valids{$_};
            $c->reply_invalid_param("Skill ID $_ não é válido", 'form_error', 'skills');
        }

        $c->cliente_set_skill(
            user   => $c->stash('user'),
            skills => [keys %valids]
        );
    }

    if (keys %$valid > 0) {
        $user_obj->update($valid);
    }

    $user_obj->discard_changes;
    $c->stash('user' => {$user_obj->get_columns});    # ATUALIZAR AQUI

    &find($c);
}


sub inc_call_police_counter {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');
    $user_obj->update(
        {
            qtde_ligar_para_policia => \'qtde_ligar_para_policia+1',
        }
    );
    $user_obj->cliente_ativacoes_policias->create({created_at => \'NOW()'});

    return $c->render(text => '', status => 204,);
}

sub route_cliente_modo_camuflado_toggle {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        active => {required => 1, type => 'Int', max_length => 1},
    );

    $user_obj->cliente_modo_camuflado_toggle(%$valid);

    return $c->render(text => '', status => 204,);
}

sub route_cliente_modo_anonimo_toggle {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        active => {required => 1, type => 'Int', max_length => 1},
    );

    $user_obj->cliente_modo_anonimo_toggle(%$valid);

    return $c->render(text => '', status => 204,);
}

sub route_cliente_ja_foi_vitima_de_violencia_toggle {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        active => {required => 1, type => 'Int', max_length => 1},
    );

    $user_obj->cliente_ja_foi_vitima_de_violencia_toggle(%$valid);

    return $c->render(text => '', status => 204,);
}


1;
