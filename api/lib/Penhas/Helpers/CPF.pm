package Penhas::Helpers::CPF;
use common::sense;
use Carp qw/croak/;
use Penhas::Utils qw/exec_tx_with_retry cpf_hash_with_salt/;
use Text::Unaccent::PurePerl qw(unac_string);
use Penhas::Logger;
use utf8;

sub setup {
    my $self = shift;


    $self->helper(
        'cpf_lookup' => sub {
            my ($c, %opts) = @_;
            my $cpf     = $opts{cpf}     || croak 'missing cpf';
            my $dt_nasc = $opts{dt_nasc} || croak 'missing dt_nasc';

            my $cpf_hashed = cpf_hash_with_salt($cpf);

            my $found = $self->schema->resultset('CpfCache')->search(
                {cpf_hashed => $cpf_hashed, dt_nasc => $dt_nasc},
                {'+columns' => [{age => \"extract('epoch' from now() - me.__created_at_real)"}]}
            )->next;

            if ($found && $found->nome_hashed eq '404' && $found->get_column('age') > 300) {
                $found->delete;    # apaga por causa da PK
                $found = undef;    # faz novamente a consulta
            }

            return $found if $found;

            state $ua = Mojo::UserAgent->new();

            die 'Configurar IWEB_SERVICE_CHAVE' unless $ENV{IWEB_SERVICE_CHAVE};

            $dt_nasc =~ /(\d{4})-(\d{2})-(\d{2})/;
            my $dataNascimento = "$3/$2/$1";
            log_info("Buscando $dataNascimento $cpf...");

            my $tx = &exec_tx_with_retry(
                sub {
                    $self->ua->get(
                        'http://ws.iwebservice.com.br/CPF/' => {} => form => {
                            chave          => $ENV{IWEB_SERVICE_CHAVE},
                            cpf            => $cpf,
                            dataNascimento => $dataNascimento,
                            formato        => 'JSON',

                        }
                    );
                },
                tries => 3
            );
            slog_info('Resposta para consulta %s: CODE=%s BODY=%s', $cpf, $tx->res->code, $tx->res->body);
            my $json = $tx->res->json;
            if ($tx->res->code == 500) {
                die {
                    error   => 'cpf_offline',
                    message => 'Não conseguimos consultar o seu CPF no momento, tente novamente mais tarde.',
                };
            }

            # dados encontrados e da match na data de nascimento
            if ($json->{RetornoCpf}{msg}{Resultado} == 1) {

                my $nome = uc(unac_string($json->{RetornoCpf}{DadosTitular}{Titular}));

                return $self->schema->resultset('CpfCache')->create(
                    {
                        cpf_hashed  => cpf_hash_with_salt($cpf),
                        dt_nasc     => $dt_nasc,
                        nome_hashed => cpf_hash_with_salt($nome),
                        situacao    => $json->{RetornoCpf}{DadosTitular}{Situacao},
                        genero      => $json->{RetornoCpf}{DadosTitular}{Genero},
                    }
                );
            }
            else {

                # nao ta certo, entao vamos salvar no banco pra nao precisar ir la novamente
                return $self->schema->resultset('CpfCache')->create(
                    {
                        cpf_hashed  => $cpf_hashed,
                        dt_nasc     => $dt_nasc,
                        nome_hashed => '404',
                        situacao    => '404',
                        genero      => undef,
                    }
                );

            }

            $c->render(json => $json);

        }
    );


}


1;
