package Penhas::Controller::Me;
use Mojo::Base 'Penhas::Controller';
use Carp;
use DateTime;
use JSON;
use Penhas::Types qw/IntList Raca/;
use MooseX::Types::Email qw/EmailAddress/;
use Digest::SHA qw/sha256_hex/;
use Scope::OnExit;
use Penhas::Controller::Logout;
use Penhas::Utils qw/check_password_or_die check_email_mx/;

sub check_and_load {
    my $c = shift;

    die 'missing user_id' unless $c->stash('user_id');
    return 1 if $c->stash('user_obj');

    my $user = $c->schema2->resultset('Cliente')->search(
        {
            'id'     => $c->stash('user_id'),
            'status' => 'active',
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

sub me_find {
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

sub me_update {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');
    my $valid    = $c->validate_request_params(
        skills        => {required   => 0,    type     => IntList, empty_is_valid => 1,},
        skills_remove => {required   => 0,    type     => 'Bool'},
        apelido       => {max_length => 40,   required => 0, type => 'Str', min_length => 2},
        senha         => {max_length => 200,  required => 0, type => 'Str'},
        minibio       => {max_length => 2200, required => 0, type => 'Str'},
        email         => {max_length => 200,  required => 0, type => EmailAddress},
        raca          => {required   => 0,    type     => Raca},
    );

    if ((exists $valid->{email} && $valid->{email}) || (exists $valid->{senha} && $valid->{senha})) {
        my $data = $c->validate_request_params(
            senha_atual => {max_length => 200, required => 1, type => 'Str'},
        );

        my $senha = sha256_hex($data->{senha_atual});
        if (lc($senha) ne lc($user_obj->senha_sha256())) {
            $c->reply_invalid_param('Senha atual não confere.', 'form_error', 'senha_atual');
        }
    }

    if (exists $valid->{email}) {
        my $email = lc(delete $valid->{email});
        my $lock  = "email:$email";
        $c->kv()->lock_and_wait($lock);
        on_scope_exit { $c->kv()->unlock($lock) };

        my $in_use = $c->schema2->resultset('Cliente')->search(
            {
                'id'    => {'!=' => $user_obj->id},
                'email' => $email,
            }
        )->count > 0;
        $c->reply_invalid_param('O e-mail já está em uso em outra conta', 'form_error', 'email', 'duplicate')
          if $in_use;


        if (!check_email_mx($email)) {
            die {
                error   => 'invalid_email',
                message => 'Por favor, verificar validade do endereço de e-mail.'
            };
        }

        $user_obj->update({email => $email});
    }

    if (exists $valid->{senha} && $valid->{senha}) {
        check_password_or_die($valid->{senha});
        $valid->{senha_sha256} = lc(sha256_hex(delete $valid->{senha}));
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

    &me_find($c);
}

sub me_delete_text {
    my $c = shift;

    return $c->render(
        json => {
            text =>
              "<p>O seu perfil será desativado por 30 dias, após este período seus dados serão completamente excluídos.<br/></p>"
              . "<p>Caso entre novamente no aplicativo antes deste período, você ainda poderá reativar o perfil.<p>"
        },
        status => 200,
    );
}

sub me_unread_notif_count {
    my $c     = shift;
    my $count = $c->user_notifications_unread_count($c->stash('user_id'));

=pod
    if ($c->stash('user_id') == 180 || $c->stash('user_id') == 3933) {
        $count = int(rand() * 10000);
        if ($count =~ /^[12]/) {
            $count = 1 + substr($count, -2, 1);
        }
        elsif ($count =~ /^[345]/) {
            $count = substr($count, 0, 2);
        }
        elsif ($count =~ /^[67]/) {
            $count = substr($count, 0, 3);
        }
    }
=cut

    return $c->render(
        json   => {count => $count},
        status => 200,
    );
}

sub me_notifications {
    my $c     = shift;
    my $valid = $c->validate_request_params(
        next_page => {max_length => 9999, required => 0, type => 'Str'},
        rows      => {required   => 0,    type     => 'Int'},
    );

    my $user_obj = $c->stash('user_obj');

    return $c->render(
        json => $c->user_notifications(
            user_obj => $user_obj,
            %$valid,
        ),
        status => 200,
    );
}

sub me_add_report_profile {
    my $c = shift;

    my $valid = $c->validate_request_params(
        reason     => {required => 1, type => 'Str', max_length => 200},
        cliente_id => {required => 1, type => 'Int'},
    );

    my $user_obj = $c->stash('user_obj');
    my $report   = $c->add_report_profile(
        user_obj => $user_obj,
        %$valid,
    );

    return $c->render(
        json   => {message => 'Sua denúncia foi recebida com sucesso.'},
        status => 200,
    );
}

sub me_add_block_profile {
    my $c = shift;

    my $valid = $c->validate_request_params(
        cliente_id => {required => 1, type => 'Int'},
    );

    my $user_obj = $c->stash('user_obj');
    my $report   = $c->add_block_profile(
        user_obj => $user_obj,
        %$valid,
    );

    return $c->render(
        json   => {message => 'O usuário foi bloqueado com sucesso.'},
        status => 200,
    );
}

sub me_delete {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $valid = $c->validate_request_params(
        senha_atual => {max_length => 200, required => 1, type => 'Str', min_length => 6},
        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );

    my $senha = sha256_hex($valid->{senha_atual});
    if (lc($senha) ne lc($user_obj->senha_sha256())) {
        $c->reply_invalid_param('Senha atual não confere.', 'form_error', 'senha_atual');
    }

    my $remote_ip = $c->remote_addr();

    $c->schema2->txn_do(
        sub {
            $user_obj->update(
                {
                    status                 => 'deleted_scheduled',
                    deleted_scheduled_meta => to_json(
                        {
                            epoch       => time(),
                            app_version => $valid->{app_version},
                            ip          => $remote_ip,
                            delete      => 1,
                            (
                                $user_obj->deleted_scheduled_meta()
                                ? (previous => from_json($user_obj->deleted_scheduled_meta() || '{}'))
                                : ()
                            ),
                        }
                    ),
                    perform_delete_at => \"NOW() + INTERVAL '30 DAY'"
                }
            );

            my $email_db = $c->schema->resultset('EmaildbQueue')->create(
                {
                    config_id => 1,
                    template  => 'account_deletion.html',
                    to        => $user_obj->email,
                    subject   => 'PenhaS - Remoção de conta',
                    variables => encode_json(
                        {
                            nome_completo => $user_obj->nome_completo,
                            remote_ip     => $remote_ip,
                            app_version   => $valid->{app_version},
                            email         => $user_obj->email,
                            cpf           => substr($user_obj->cpf_prefix, 0, 3)
                        }
                    ),
                }
            );
            die 'missing id' unless $email_db;

            # apaga todas as sessions ativas (pode ter mais de uma dependendo da configuracao)
            $user_obj->clientes_active_sessions->delete;
        }
    );

    # faz logout da session atual (apaga no cache, etc)
    &Penhas::Controller::Logout::logout_post($c);
}

sub me_reactivate {
    my $c = shift;

    my $valid = $c->validate_request_params(
        app_version => {max_length => 800, required => 1, type => 'Str', min_length => 1},
    );
    my $user_obj = $c->schema2->resultset('Cliente')->search(
        {
            'id'           => $c->stash('user_id'),
            'status'       => 'deleted_scheduled',
            'login_status' => 'OK',
        },
    )->next;

    $c->reply_not_found() unless $user_obj;
    my $remote_ip = $c->remote_addr();

    $c->schema2->txn_do(
        sub {
            $user_obj->update(
                {
                    status                 => 'active',
                    deleted_scheduled_meta => to_json(
                        {
                            epoch       => time(),
                            app_version => $valid->{app_version},
                            ip          => $remote_ip,
                            reactivate  => 1,
                            previous    => from_json($user_obj->deleted_scheduled_meta() || '{}'),
                        }
                    ),
                    perform_delete_at => undef,
                }
            );

            my $email_db = $c->schema->resultset('EmaildbQueue')->create(
                {
                    config_id => 1,
                    template  => 'account_reactivate.html',
                    to        => $user_obj->email,
                    subject   => 'PenhaS - Reativação de conta',
                    variables => encode_json(
                        {
                            nome_completo => $user_obj->nome_completo,
                            remote_ip     => $remote_ip,
                            app_version   => $valid->{app_version},
                            email         => $user_obj->email,
                            cpf           => substr($user_obj->cpf_prefix, 0, 3)
                        }
                    ),
                }
            );
            die 'missing id' unless $email_db;
        }
    );

    return $c->render(text => '', status => 204,);
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
