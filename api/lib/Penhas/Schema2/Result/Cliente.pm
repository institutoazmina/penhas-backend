#<<<
use utf8;
package Penhas::Schema2::Result::Cliente;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "setup",
    is_nullable => 0,
    size => 20,
  },
  "created_on",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "cpf_hash",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cpf_prefix",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "dt_nasc",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "cep",
  { data_type => "varchar", is_nullable => 0, size => 8 },
  "cep_cidade",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "cep_estado",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "genero",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "raca",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "minibio",
  { data_type => "varchar", is_nullable => 1, size => 2200 },
  "nome_completo",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "login_status",
  { data_type => "varchar", default_value => "OK", is_nullable => 1, size => 20 },
  "login_status_last_blocked_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "ja_foi_vitima_de_violencia",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 1 },
  "senha_sha256",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "modo_camuflado_ativo",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "modo_anonimo_ativo",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "ja_foi_vitima_de_violencia_atualizado_em",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "qtde_login_senha_normal",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "apelido",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "nome_social",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "avatar_url",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "genero_outro",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "upload_status",
  { data_type => "varchar", default_value => "ok", is_nullable => 1, size => 20 },
  "qtde_ligar_para_policia",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "modo_anonimo_atualizado_em",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "modo_camuflado_atualizado_em",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "qtde_guardioes_ativos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "salt_key",
  { data_type => "char", is_nullable => 0, size => 10 },
  "quiz_detectou_violencia",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 1 },
  "quiz_detectou_violencia_atualizado_em",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("cpf_hash", ["cpf_hash"]);
__PACKAGE__->add_unique_constraint("email", ["email"]);
__PACKAGE__->might_have(
  "chat_support",
  "Penhas::Schema2::Result::ChatSupport",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "chat_support_messages",
  "Penhas::Schema2::Result::ChatSupportMessage",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "cliente_ativacoes_panicoes",
  "Penhas::Schema2::Result::ClienteAtivacoesPanico",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "cliente_ativacoes_policias",
  "Penhas::Schema2::Result::ClienteAtivacoesPolicia",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "cliente_bloqueios",
  "Penhas::Schema2::Result::ClienteBloqueio",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "cliente_ponto_apoio_avaliacaos",
  "Penhas::Schema2::Result::ClientePontoApoioAvaliacao",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "cliente_skills",
  "Penhas::Schema2::Result::ClienteSkill",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_active_sessions",
  "Penhas::Schema2::Result::ClientesActiveSession",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->might_have(
  "clientes_app_activity",
  "Penhas::Schema2::Result::ClientesAppActivity",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_audios",
  "Penhas::Schema2::Result::ClientesAudio",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_audios_eventos",
  "Penhas::Schema2::Result::ClientesAudiosEvento",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_guardioes",
  "Penhas::Schema2::Result::ClientesGuardio",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_quiz_sessions",
  "Penhas::Schema2::Result::ClientesQuizSession",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "clientes_reset_passwords",
  "Penhas::Schema2::Result::ClientesResetPassword",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "login_erros",
  "Penhas::Schema2::Result::LoginErro",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "login_logs",
  "Penhas::Schema2::Result::LoginLog",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "media_uploads",
  "Penhas::Schema2::Result::MediaUpload",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "ponto_apoio_sugestoes",
  "Penhas::Schema2::Result::PontoApoioSugestoe",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tweets",
  "Penhas::Schema2::Result::Tweet",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tweets_likes",
  "Penhas::Schema2::Result::TweetLikes",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "tweets_reports",
  "Penhas::Schema2::Result::TweetsReport",
  { "foreign.cliente_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-10-20 11:25:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i0812Nd/0oGfmps8hTsY9A

use Carp qw/confess/;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
use Scope::OnExit;
use Penhas::KeyValueStorage;

__PACKAGE__->has_many(
    cliente_bloqueios_custom => 'Penhas::Schema2::Result::ClienteBloqueio',
    sub {
        my $args = shift;

        return {
            "$args->{foreign_alias}.cliente_id"         => {-ident => "$args->{self_alias}.id"},
            "$args->{foreign_alias}.blocked_cliente_id" => \' = ? '
        };
    }
);


sub is_female {
    my $self = shift;
    return $self->genero() =~ /^(Feminino|MulherTrans)$/ ? 1 : 0;
}

has 'access_modules' => (is => 'rw', lazy => 1, builder => '_build_access_modules');

sub _build_access_modules {
    my $self = shift;

    my @modules;
    if ($self->is_female) {
        push @modules,
          qw/tweets chat_privado chat_suporte pontos_de_apoio modo_seguranca/;
    }
    else {
        push @modules, qw/chat_suporte pontos_de_apoio/;
    }

    return {map { ($_ => {}) } @modules};
}

sub access_modules_as_config {
    my $meta = {
        chat_privado => {
            polling_rate => '20',
        },
        chat_suporte => {
            polling_rate => '20',
        },
        modo_seguranca => {
            numero              => '000',
            audio_each_duration => '30',
            audio_full_duration => '900',

            audio_each_duration => '900',
            audio_full_duration => '900',
        },
        tweets => {
            max_length => 2200,
        },

    };
    return [map { +{code => $_, meta => $meta->{$_} || {}} } keys $_[0]->access_modules->%*];
}

sub access_modules_str {
    return ',' . join(',', keys $_[0]->access_modules->%*) . ',';
}

sub has_module {
    my $self   = shift;
    my $module = shift || confess 'missing module name';

    return $self->access_modules_str() =~ /,$module,/;
}

sub cliente_modo_camuflado_toggle {
    my ($self, %opts) = @_;
    my $active = $opts{active};

    $self->update(
        {
            modo_camuflado_ativo         => $active ? 1 : 0,
            modo_camuflado_atualizado_em => \'NOW(4)',
        }
    );
}

sub cliente_modo_anonimo_toggle {
    my ($self, %opts) = @_;
    my $active = $opts{active};

    $self->update(
        {
            modo_anonimo_ativo         => $active ? 1 : 0,
            modo_anonimo_atualizado_em => \'NOW(4)',
        }
    );

}

sub cliente_ja_foi_vitima_de_violencia_toggle {
    my ($self, %opts) = @_;
    my $active = $opts{active};

    $self->update(
        {
            ja_foi_vitima_de_violencia               => $active ? 1 : 0,
            ja_foi_vitima_de_violencia_atualizado_em => \'NOW(4)',
        }
    );

}

sub quiz_detectou_violencia_toggle {
    my ($self, %opts) = @_;
    my $active = $opts{active};

    $self->update(
        {
            quiz_detectou_violencia_atualizado_em => \'NOW(4)',
            quiz_detectou_violencia               => $active ? '1' : '0',
        }
    );

}

# retorna o string para ser usada em FK composta
sub id_composed_fk {
    return shift()->id . ':' . shift;
}

sub recalc_qtde_guardioes_ativos {
    my ($self) = @_;

    return $self->update(
        {
            qtde_guardioes_ativos => \[
                "(select count(1) from clientes_guardioes cg where cg.cliente_id = ? and cg.status= 'accepted')",
                [$self->id()]
            ]
        }
    );
}

sub cep_formmated {
    my ($self) = @_;
    my $cep = $self->cep;
    $cep =~ s/(.{5})(.{3})/$1-$2/;
    return $cep;
}

sub update_activity {
    my ($self, $is_timeline) = @_;

    return if $ENV{SUPPRESS_USER_ACTIVITY};
    my $key = "ua" . ($is_timeline ? 't:' : ':') . $self->id;

    my $kv = Penhas::KeyValueStorage->instance;

    # atualiza de 5 em 5min o banco
    my $recent_activities = $kv->redis->get($ENV{REDIS_NS} . $key);
    return if $recent_activities;
    $kv->redis->setex($ENV{REDIS_NS} . $key, 60 * 5, 1);

    my $lock = "update_activity:user:" . $self->id;
    $kv->lock_and_wait($lock);
    on_scope_exit { $kv->unlock($lock) };

    my $activity = $self->clientes_app_activity;
    if ($activity) {
        $activity->update(
            {
                (
                    $is_timeline
                    ? (
                        last_tm_activity => \'now(6)',    # MariaDB only now with precision
                      )
                    : ()
                ),
                last_activity => \'now(6)',
            }
        );
    }
    else {
        $self->create_related(
            'clientes_app_activity',
            {
                last_activity    => \'now(6)',
                last_tm_activity => \'now(6)',
            }
        );
    }
}

sub support_chat_auth {
    return 'S' . substr($_[0]->cpf_hash, 0, 4);
}

sub assistant_session_id {
    return 'A' . substr($_[0]->cpf_hash, 0, 4);
}

sub name_for_admin {
    return $_[0]->apelido . ' (' . $_[0]->nome_completo . ')';
}

sub avatar_url_or_default {
    return $_[0]->avatar_url() || $ENV{AVATAR_PADRAO_URL};
}

sub reset_all_questionnaires {
    my ($self) = @_;

    $self->clientes_quiz_sessions->search({deleted_at => undef})->update(
        {
            deleted    => 1,
            deleted_at => \'NOW(4)',
        }
    );
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
