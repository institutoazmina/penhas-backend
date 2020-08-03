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
  "panic_status_last_blocked_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "panic_status",
  { data_type => "varchar", default_value => "OK", is_nullable => 1, size => 20 },
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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("cpf_hash", ["cpf_hash"]);
__PACKAGE__->add_unique_constraint("email", ["email"]);
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
  "cliente_skills",
  "Penhas::Schema2::Result::ClienteSkill",
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
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-03 07:23:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:39Ohmupn5NgCWjBjGRDX+A

use Carp qw/confess/;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;

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
          qw/tweets chat_privado chat_suporte noticias modo_camuflado modo_anonimo pontos_de_apoio modo_seguranca/;
    }
    else {
        push @modules, qw/chat_suporte noticias pontos_de_apoio/;
    }

    return {map { ($_ => {}) } @modules};
}

sub access_modules_as_config {
    my $meta = {modo_seguranca => {numero => '000',}, tweets => {max_length => 2200,},};
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
            modo_camuflado_atualizado_em => \'NOW()',
        }
    );
}

sub cliente_modo_anonimo_toggle {
    my ($self, %opts) = @_;
    my $active = $opts{active};

    $self->update(
        {
            modo_anonimo_ativo         => $active ? 1 : 0,
            modo_anonimo_atualizado_em => \'NOW()',
        }
    );

}

# retorna o string para ser usada em FK composta
sub id_composed_fk {
    return shift()->id . ':' . shift;
}

sub recalc_qtde_guardioes_ativos {
    my ($self) = @_;

    return $self->update({
        qtde_guardioes_ativos => \["(select count(1) from clientes_guardioes cg where cg.cliente_id = ? and cg.status= 'accepted')", [$self->id()]]
    });  
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
