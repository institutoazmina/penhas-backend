package Penhas::Helpers::ClienteSetSkill;
use common::sense;
use Penhas::Directus;
use Carp qw/croak/;
use utf8;
use JSON;
use Penhas::Logger;

sub setup {
    my $self = shift;

    $self->helper('cliente_set_skill' => sub { &cliente_set_skill(@_) });
}


sub cliente_set_skill {
    my ($c, %opts) = @_;

    my $user   = $opts{user}   or croak 'missing user';
    my $skills = $opts{skills} or croak 'missing skills';

    my $rs             = $c->schema2->resultset('ClienteSkill');
    my $current_skills = {
        map { $_->{skill_id} => $_->{id} } $rs->search(
            {cliente_id => $user->{id}},
            {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                columns      => [qw/skill_id id/]
            }
        )->all
    };

    slog_info(
        "current cliente_skills (old): is %s, new set is %s",
        (join ',', sort keys %$current_skills),
        (join ',', $opts{skills}->@*),
    );

    # percorre os skills desejados
    foreach my $skill ($opts{skills}->@*) {

        # nao existe, precisa inserir
        if (!$current_skills->{$skill}) {
            slog_info("Adding new skill %s", $skill);
            $rs->create({cliente_id => $user->{id}, skill_id => $skill});
        }

        # remove da lista de "atuais"
        delete $current_skills->{$skill};
    }

    # remove o que sobrou dos "atuais"
    my @ids = values $current_skills->%*;
    $rs->search({id => {in => \@ids}})->delete() if @ids;

    return;
}

1;
