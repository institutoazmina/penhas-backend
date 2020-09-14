package Penhas::Controller::Skills;
use utf8;
use Mojo::Base 'Penhas::Controller';
use Penhas::Utils qw/is_test/;
use Penhas::KeyValueStorage;

sub filter_skills {
    my $c = shift;

    my $skills = Penhas::KeyValueStorage->instance->redis_get_cached_or_execute(
        "skills_filter",
        3600,    # 1 hour
        sub {
            my @skills = $c->schema2->resultset('Skill')->search(
                {
                    'me.status' => 'published',
                },
                {
                    columns => [
                        (qw/me.id me.skill/),
                    ],
                    order_by     => 'me.sort',
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
                }
            )->all;

            return {
                skills => \@skills,
            };
        }
    );

    return $c->render(json => $skills);
}

1;
