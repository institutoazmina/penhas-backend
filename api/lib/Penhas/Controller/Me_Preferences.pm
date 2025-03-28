package Penhas::Controller::Me_Preferences;
use Mojo::Base 'Penhas::Controller';
use Scope::OnExit;
use Penhas::Utils qw/is_test/;
use DateTime;

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user');
    return 1;
}

sub list_preferences {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    return $c->list_preferences_man() unless ($user_obj->is_female());

    my %prefs = map { $_->get_column('name') => $_->get_column('value') } $user_obj->clientes_preferences->search(
        undef,
        {
            join    => 'preference',
            columns => [{name => 'preference.name'}, qw/me.value/],
        }
    )->all;

    my $rs = $c->schema2->resultset('Preference')->search(
        {'me.active' => '1'},
        {
            columns      => [qw/me.name me.label me.initial_value/],
            order_by     => ['sort'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    );

    # filtra as que são para admin caso não seja admin
    $rs = $rs->search({admin_only => 0}) unless $user_obj->eh_admin;

    my @all_badges = $c->schema2->resultset('Badge')->search(
        {
            'me.linked_cep_cidade' => {'!=' => undef},
        },
        {
            select       => ['me.linked_cep_cidade'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->all;
    my @badge_cities = map { $_->{linked_cep_cidade} } @all_badges;

    my $my_city = $user_obj->cep_cidade;

    my @prefs;
    while (my $pref = $rs->next) {
        my $name  = $pref->{name};
        my $value = exists $prefs{$name} ? $prefs{$name} : $pref->{initial_value};

        if ($name eq 'NOTIFY_POST_FROM_BADGE_HOLDER_FOR_LINKED_CITY') {

            my $has_badge = $user_obj->cliente_tags->search(
                {
                    'badge.linked_cep_cidade' => {'!=' => undef},
                },
                {
                    join => 'badge',
                }
            )->count;
            next unless $has_badge;
        }

        if ($name eq 'NOTIFY_POST_FROM_BADGE_HOLDER_IN_MY_CITY') {
            my $my_city_in_badge = grep { $_ eq $my_city } @badge_cities;
            next unless $my_city_in_badge;
        }

        push @prefs, {
            key   => $name,
            value => $value ? '1' : '0',
            label => $pref->{label},
            type  => 'boolean',
        };
    }

    return $c->render(
        json   => {preferences => \@prefs},
        status => 200,
    );
}

sub list_preferences_man {
    my $c = shift;

    return $c->render(
        json   => {preferences => []},
        status => 200,
    );
}

sub post_preferences {
    my $c = shift;

    my $user_obj = $c->stash('user_obj');

    my $rs = $c->schema2->resultset('Preference')->search(
        {'me.active' => '1'},
        {
            columns      => [qw/me.name me.id/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    );


    # faz o lock por causa do update-then-insert
    my $lock = "write_prefs:" . $user_obj->id();
    $c->kv()->lock_and_wait($lock);
    on_scope_exit { $c->kv()->unlock($lock) };

    my $params = $c->req->params->to_hash;

    while (my $pref = $rs->next) {

        my $name = $pref->{name};
        next unless exists $params->{$name};

        $c->validate_request_params(
            $name => {required => 1, type => 'Bool'},
        );
        my $value = $params->{$name};

        my $updated = $user_obj->clientes_preferences->search({preference_id => $pref->{id}})->update(
            {
                updated_at => \'now()',
                value      => $value,
            }
        );

        # nenhum resultado atualizado, entao precisa inserir.
        if ($updated == 0) {
            $user_obj->clientes_preferences->create(
                {
                    updated_at    => \'now()',
                    created_at    => \'now()',
                    preference_id => $pref->{id},
                    value         => $value,
                }
            );
        }
    }

    return &list_preferences($c) unless is_test();

    return $c->render(
        text   => '',
        status => 204,
    );
}

1;
