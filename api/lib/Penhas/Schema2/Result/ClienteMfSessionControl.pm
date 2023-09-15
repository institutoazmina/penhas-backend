#<<<
use utf8;
package Penhas::Schema2::Result::ClienteMfSessionControl;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'Penhas::Schema::Base';
__PACKAGE__->table("cliente_mf_session_control");
__PACKAGE__->add_columns(
  "cliente_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status",
  {
    data_type     => "text",
    default_value => "onboarding",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "current_clientes_quiz_session",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "completed_questionnaires_id",
  {
    data_type     => "integer[]",
    default_value => \"'{}'::integer[]",
    is_nullable   => 0,
  },
  "started_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "completed_at",
  { data_type => "timestamp", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cliente_id");
__PACKAGE__->belongs_to(
  "cliente",
  "Penhas::Schema2::Result::Cliente",
  { id => "cliente_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "current_clientes_quiz_session",
  "Penhas::Schema2::Result::ClientesQuizSession",
  { id => "current_clientes_quiz_session" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-06-16 03:00:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HU6o12q180TXkn/uKyPqMQ

# -- statuses:
# -- onboarding
# -- inProgress
# -- completed

use Penhas::Utils;

sub register_session_start {
    my ($self, %opts) = @_;

    $self->update(
        {
            started_at                    => \'now()',
            current_clientes_quiz_session => $opts{session_id},
            status                        => 'inProgress'
        }
    );
}

sub register_completed_questionnaire {
    my ($self, %opts) = @_;

    my $completed_questionnaires_id = [@{$self->completed_questionnaires_id}, $opts{questionnaire_id}];

    $self->update(
        {
            completed_questionnaires_id => $completed_questionnaires_id,
        }
    );
}

# busca o proximo questionario que não foi completado
sub get_next_questionnaire_id {
    my ($self, %opts) = @_;
    my $published = is_test() ? 'testing' : 'published';

    my $outstanding = $opts{outstanding} ? $opts{outstanding} : 0;

    my $completed_questionnaires_id = $self->completed_questionnaires_id;
    $completed_questionnaires_id = [] unless $completed_questionnaires_id;

    if ($outstanding) {

        # busca pelo outstanding se não tiver sido respondido ainda
        # isso é pra fazer pular na frente dos outros items
        my $pending = $self->result_source->schema->resultset('MfQuestionnaireOrder')->search(
            {
                'me.published'         => $published,
                'me.questionnaire_id'  => {'not in' => $completed_questionnaires_id},
                'me.outstanding_order' => $outstanding
            },
            {order_by => 'sort', rows => 1}
        )->get_column('questionnaire_id')->next;

        return $pending if $pending;
    }

    # se não tiver, busca o normal
    return $self->result_source->schema->resultset('MfQuestionnaireOrder')->search(
        {
            'me.published'        => $published,
            'me.questionnaire_id' => {'not in' => $completed_questionnaires_id},
        },
        {order_by => 'sort', rows => 1}
    )->get_column('questionnaire_id')->next;
}

sub set_status_completed {
    my ($self, %opts) = @_;

    $self->cliente->update({ja_completou_mf => 'true'}) unless $self->cliente->ja_completou_mf;

    $self->update(
        {
            status                        => 'completed',
            completed_at                  => \'now()',
            completed_questionnaires_id   => '{}',
            current_clientes_quiz_session => undef,
        }
    );
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
