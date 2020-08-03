#<<<
use utf8;
package Penhas::Schema2::Result::ClientesGuardio;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("clientes_guardioes");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cliente_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "pending",
    is_nullable => 0,
    size => 20,
  },
  "celular_e164",
  { data_type => "varchar", is_nullable => 0, size => 25 },
  "nome",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "token",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "created_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "accepted_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "accepted_meta",
  { data_type => "text", default_value => "'{}'", is_nullable => 0 },
  "celular_formatted_as_national",
  { data_type => "varchar", is_nullable => 0, size => 25 },
  "refused_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "deleted_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "expires_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("token", ["token"]);
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-03 07:46:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iGEXINK77zEPrkudIEA91g

# ALTER TABLE clientes_guardioes ADD FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE cascade;

use JSON;

sub subtexto {
    my ($self) = @_;

    my $tmp = '';

    if ($self->status eq 'pending') {
        my $age = int((time() - $self->created_at->epoch) / 3600);

        my $expires_in = int(($self->expires_at->epoch - time()) / 3600);

        if ($expires_in <= 24) {
            $tmp = 'Convite próximo de expirar!';

        }
        elsif ($age <= 1) {
            $tmp .= 'Convite enviado há pouco tempo';
        }
        elsif ($age <= 24) {
            $tmp = sprintf('Convite enviado há %d horas.', $age);
        }
        else {
            $tmp = sprintf('Convite enviado há %d dias.', int($age / 24));
        }
    }
    elsif ($self->status eq 'expired_for_not_use') {
        $tmp = sprintf('Convite expirou em %s', $self->expires_at->ymd('/'));
    }
    elsif ($self->status eq 'refused' && $self->refused_at) {
        $tmp = sprintf('Convite recusado em %s', $self->refused_at->ymd('/'));
    }

    return $tmp;
}

sub accepted_meta_merge_with {
    my ($self, $merge_with) = @_;

    my $cur_value = eval { from_json($self->accepted_meta) } || {};

    $cur_value->{$_} = $merge_with->{$_} for keys $merge_with->%*;

    return to_json($cur_value);
}

sub render_guardiao_public_data {
    my ($self) = @_;

    my $cliente = $self->cliente;

    return {
        guardiao => {
            celular => $self->celular_formatted_as_national(),

            is_accepted => $self->status eq 'accepted'            ? 1 : 0,
            is_pending  => $self->status eq 'pending'             ? 1 : 0,
            is_expired  => $self->status eq 'expired_for_not_use' ? 1 : 0,
            nome  => $self->nome,

            refused_at  => ($self->refused_at()  ? $self->refused_at->datetime()  : undef),
            created_at  => ($self->created_at()  ? $self->created_at->datetime()  : undef),
            accepted_at => ($self->accepted_at() ? $self->accepted_at->datetime() : undef),
        },
        cliente => {
            apelido => $cliente->apelido,
        }
    };
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
