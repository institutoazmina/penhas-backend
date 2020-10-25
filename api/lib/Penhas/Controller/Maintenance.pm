package Penhas::Controller::Maintenance;
use Mojo::Base 'Penhas::Controller';

sub check_authorization {
    my $c = shift;

    my $params = $c->req->params->to_hash;
    $c->validate_request_params(
        secret => {required => 1, type => 'Str', max_length => 100},
    );

    $c->reply_forbidden() unless $params->{secret} eq ($ENV{MAINTENANCE_SECRET} || die 'missing MAINTENANCE_SECRET');

    return 1;
}

# executa tarefas para manter o banco atualizado, mas não necessáriamente essenciais
# executar de 1 em 1 hora, por exemplo
sub housekeeping {
    my $c = shift;

    $c->schema2->resultset('ClientesAudiosEvento')->tick_audios_eventos_status();
    $c->tick_ponto_apoio_index();

    return $c->render(json => {});
}

1;
