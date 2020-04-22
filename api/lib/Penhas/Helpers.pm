package Penhas::Helpers;
use common::sense;
use Penhas::SchemaConnected;
use Penhas::Directus;
use Penhas::Controller;
use Penhas::Utils qw/exec_tx_with_retry/;

use Carp qw/croak/;

sub setup {
    my $self = shift;

    $self->helper(schema => sub { state $schema = Penhas::SchemaConnected->get_schema(@_) });

    $self->helper(
        remote_addr => sub {
            my $c = shift;

            foreach my $place (@{['cf-connecting-ip', 'x-real-ip', 'x-forwarded-for', 'tx']}) {
                if ($place eq 'cf-connecting-ip') {
                    my $ip = $c->req->headers->header('cf-connecting-ip');
                    return $ip if $ip;
                }
                elsif ($place eq 'x-real-ip') {
                    my $ip = $c->req->headers->header('X-Real-IP');
                    return $ip if $ip;
                }
                elsif ($place eq 'x-forwarded-for') {
                    my $ip = $c->req->headers->header('X-Forwarded-For');
                    return $ip if $ip;
                }
                elsif ($place eq 'tx') {
                    my $ip = $c->tx->remote_address;
                    return $ip if $ip;
                }
            }

            return;
        },
    );

    $self->helper('reply.exception' => sub { Penhas::Controller::reply_exception(@_) });
    $self->helper('reply.not_found' => sub { Penhas::Controller::reply_not_found(@_) });
    $self->helper('user_not_found'  => sub { Penhas::Controller::reply_not_found(@_, type => 'user_not_found') });

    $self->helper(directus => sub { Penhas::Directus->instance });

    $self->helper(
        'cpf_lookup' => sub {
            my ($c, %opts) = @_;
            my $cpf     = $opts{cpf}     || croak 'missing cpf';
            my $dt_nasc = $opts{dt_nasc} || croak 'missing dt_nasc';

            my $found = $self->schema->resultset('CpfCache')->search({cpf => $cpf})->next;

            return $found if $found;

            state $ua = Mojo::UserAgent->new();

            die 'Configurar IWEB_SERVICE_CHAVE' unless $ENV{IWEB_SERVICE_CHAVE};

            $dt_nasc =~ /(\d{4})-(\d{2})-(\d{2})/;
            my $dataNascimento = "$3/$2/$1";

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
