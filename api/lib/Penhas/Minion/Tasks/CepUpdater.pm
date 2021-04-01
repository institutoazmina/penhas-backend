package Penhas::Minion::Tasks::CepUpdater;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Penhas::CEP;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(cliente_update_cep => \&cliente_update_cep);
}

sub cliente_update_cep {
    my ($job, $user_id) = @_;

    sleep 1 until my $guard = $job->minion->guard('cliente_update_cep', 3600, {limit => 4});

    log_trace("minion:cliente_update_cep", $user_id);

    my $schema2 = $job->app->schema2;    # mysql

    my $logger = $job->app->log;

    my $user = $schema2->resultset('Cliente')->find($user_id);
    goto OK if !$user;

    my $cep = $user->cep;
    goto OK if !$cep;

    my @_address_fields = qw(city state);

    $cep =~ s/[^0-9]//go;
    my $result;
    foreach my $backend (map { Penhas::CEP->new_with_traits(traits => $_) } qw(Postmon Correios)) {
        $result = $backend->find($cep);
        if ($result) {

            # pula proximo backend se todos os campos estão preenchidos
            last if (grep { length $result->{$_} } @_address_fields) == @_address_fields;
        }
    }

    die "cep $cep não encontrado" unless $result;

    $user->update(
        {
            cep_estado => $result->{'state'},
            cep_cidade => $result->{'city'},
        }
    );

  OK:
    return $job->finish(1);
}

1;
