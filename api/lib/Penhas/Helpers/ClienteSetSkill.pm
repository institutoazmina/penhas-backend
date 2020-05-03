package Penhas::Helpers::ClienteSetSkill;
use common::sense;
use Penhas::Directus;
use Carp qw/croak/;

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

    my $current_skills = {
        map { $_->{skill_id} => $_->{id} } $c->directus->search(
            table => 'cliente_skills',
            form  => {'filter[cliente_id][eq]' => $user->{id}}
        )->{data}->@*
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
            $c->directus->create(
                table => 'cliente_skills',
                form  => {'cliente_id' => $user->{id}, skill_id => $skill}
            );
        }

        # remove da lista de "atuais"
        delete $current_skills->{$skill};
    }

    # remove o que sobrou dos "atuais"
    while (my ($skill, $cliente_skill_id) = each $current_skills->%*) {
        slog_info("Deleting old skill %s", $skill);
        $c->directus->delete(
            table => 'cliente_skills',
            id    => $cliente_skill_id
        );
    }

    return;
}

1;
