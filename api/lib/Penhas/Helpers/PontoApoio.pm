package Penhas::Helpers::PontoApoio;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Number::Phone::Lib;
use Penhas::Utils qw/random_string_from is_test/;
use Digest::MD5 qw/md5_hex/;
use Scope::OnExit;

sub setup {
    my $self = shift;

    $self->helper('ponto_apoio_list'    => sub { &ponto_apoio_list(@_) });
    $self->helper('ponto_apoio_fields'  => sub { &ponto_apoio_fields(@_) });
    $self->helper('ponto_apoio_suggest' => sub { &ponto_apoio_suggest(@_) });
}


sub _format_pa_row {
    my ($c, $user_obj, $row) = @_;

    return {
        (map { $_ => $row->$_ } qw/id/),
    };
}

# filtro por nota
# filtro por projeto [ímplicito]
# filtro por categoria
# ordem por distancia (pegar lat long)
# filtro por nome (generico)

sub ponto_apoio_list {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';


    return {


    };
}

sub ponto_apoio_fields {
    my ($c, %opts) = @_;

    my $is_public = defined $opts{format} && $opts{format} eq 'public';

    my @config = (


        ['endereco_ou_cep' => {max_length => 255, required => 1,},],
        ['nome'            => {max_length => 255, required => 1,},],

        [
            'categoria' => {required => 1},
            {
                options => [
                    map { +{value => $_->{id}, name => $_->{label}} }
                      $c->schema2->resultset('PontoApoioCategoria')->search(
                        {
                            status => 'prod',
                        },
                        {
                            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                            order_by     => ['label'],
                            columns      => [qw/id label/],
                        }
                    )->all()

                ]
            }
        ],
        ['descricao_servico' => {required => 1, max_length => 9999,},],

    );

    my $ret;

    my %names = (
        endereco_ou_cep   => 'Endereço ou CEP',
        descricao_servico => 'Descrição do serviço',
        nome              => 'Nome',
    );
    foreach my $item (@config) {

        $item->[1]{type}     = 'Str' unless exists $item->[1]{type};
        $item->[1]{required} = 0     unless exists $item->[1]{required};

        if ($is_public) {
            my %tmp = defined $item->[2] ? $item->[2]->%* : ();

            push $ret->@*, {
                code => $item->[0],
                name => (exists $names{$item->[0]} ? $names{$item->[0]} : &_gen_name_from_code($item->[0])),
                $item->[1]->%*,
                %tmp,
            };
        }
        else {
            $item->[1]{empty_is_invalid} = 0;
            push $ret->@*, $item->[0], $item->[1];
        }
    }

    return $ret;
}

sub _gen_name_from_code {
    my ($code) = @_;

    $code =~ s/_/ /;
    $code = join ' ', map { ucfirst($_) } split ' ', $code;

    return $code;
}


sub ponto_apoio_suggest {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';

    my $fields = $opts{fields};

    $fields->{cliente_id} = $user_obj->id;
    $fields->{metainfo}   = to_json(
        {
            ip => $c->remote_addr(),
        }
    );
    $fields->{created_at} = \'now()';


    $c->schema2->resultset('PontoApoioSugestoe')->create($fields);

    return {
        success => 1,
        message => 'Sua sugestão será avaliada antes de ser publicada.',
    };
}


1;
