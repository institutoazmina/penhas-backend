package Penhas::Helpers::CPF;
use common::sense;
use Penhas::Directus;
use Carp qw/croak/;
use Penhas::Utils qw/exec_tx_with_retry/;
use Penhas::Logger;

sub setup {
    my $self = shift;


    $self->helper(
        'cpf_lookup' => sub {
            my ($c, %opts) = @_;
            my $cpf     = $opts{cpf}     || croak 'missing cpf';
            my $dt_nasc = $opts{dt_nasc} || croak 'missing dt_nasc';

            my $found = $self->schema->resultset('CpfCache')->search({cpf => $cpf, dt_nasc => $dt_nasc})->next;

            return $found if $found;

            state $ua = Mojo::UserAgent->new();

            die 'Configurar IWEB_SERVICE_CHAVE' unless $ENV{IWEB_SERVICE_CHAVE};

            $dt_nasc =~ /(\d{4})-(\d{2})-(\d{2})/;
            my $dataNascimento = "$3/$2/$1";
            log_info("Buscando $dataNascimento $cpf...");

            my $tx = &exec_tx_with_retry(
                sub {
                    $self->ua->get(
                        'http://ws.iweb-service.com/CPF/' => {} => form => {
                            chave          => $ENV{IWEB_SERVICE_CHAVE},
                            cpf            => $cpf,
                            dataNascimento => $dataNascimento,
                            formato        => 'JSON',

                        }
                    );
                },
                tries => 3
            );
            my $json = $tx->res->json;

            # dados encontrados e da match na data de nascimento
            if ($json->{RetornoCpf}{msg}{Resultado} == 1) {

                return $self->schema->resultset('CpfCache')->create(
                    {
                        cpf      => $cpf,
                        dt_nasc  => $dt_nasc,
                        nome     => $json->{RetornoCpf}{DadosTitular}{Titular},
                        situacao => $json->{RetornoCpf}{DadosTitular}{Situacao},
                        genero   => $json->{RetornoCpf}{DadosTitular}{Genero},
                        nome_mae => $json->{RetornoCpf}{DadosTitular}{NomeMae},
                    }
                );
            }
            else {

                # nao ta certo, entao vamos salvar no banco pra nao precisar ir la novamente
                return $self->schema->resultset('CpfCache')->create(
                    {
                        cpf      => $cpf,
                        dt_nasc  => $dt_nasc,
                        nome     => '404',
                        situacao => '404',
                        genero   => undef,
                        nome_mae => undef,
                    }
                );

            }

            $c->render(json => $json);

        }
    );


}


1;
