use strict;
use Email::Valid;
use utf8;
use DateTime;

use JSON::XS;
use Text::CSV_XS;
use open qw/:std :utf8/;

use DDP;

my $file = $ARGV[0];

my $csv = Text::CSV_XS->new({binary => 1, sep_char => ';'})
  or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
open my $fh, "<:encoding(utf8)", $file or die "$file: $!";

open my $fh2, ">:encoding(utf8)", "$file.sql" or die "$file.sql $!";

my $lists = {
    map {
        my ($name, $list) = @$_;

        # transforma as chaves todas em lower-case
        ($name => {map { lc($_) => $list->{$_} } keys %$list})
    } [
        natureza => {
            'público'          => 'publico',
            'privado_coletivo' => 'privado_coletivo',
            'privado_ong'      => 'privado_ong',
        }
    ],
    [
        rua => {
            Rodovia  => 'Rodovia',
            Rua      => 'Rua',
            Avenida  => 'Avenida',
            Estrada  => 'Estrada',
            Alameda  => 'Alameda',
            Viela    => 'Viela',
            Via      => 'Via',
            Travessa => 'Travessa',
            Quadra   => 'Quadra',
            Praça    => 'Praça',
            Área     => 'Área',
            Conjunto => 'Conjunto',
            Villa    => 'Vila',
            Vila     => 'Vila',
        }
    ],
    [
        dias => {
            'Dias úteis'                                => 'dias_uteis',
            'Fim de semana'                             => 'fds',
            'Dias úteis com plantão aos fins de semana' => 'dias_uteis_fds_plantao',
            'Todos os dias'                             => 'todos_os_dias',
        }
    ],
};
$lists->{projeto} = {
    mapa_delegacia => 2,
};
$lists->{categoria} = {
    'delegacia comum'                         => 3,
    'delegacia da mulher'                     => 5,
    'posto de atendimento em delegacia comum' => 9,
};

my $headers = [
    {name => "nome",                    type => ''},
    {name => "sigla",                   type => 'uc'},
    {name => "natureza",                type => 'list', kind => 'natureza'},
    {name => "categoria",               type => 'list', kind => 'categoria'},
    {name => "projeto",                 type => 'list', kind => 'projeto'},
    {name => "tipo_logradouro",         type => 'list', kind => 'rua'},
    {name => "nome_logradouro",         type => ''},
    {name => "numero",                  type => 'ruanumero'},
    {name => "complemento",             type => ''},
    {name => "bairro",                  type => ''},
    {name => "municipio",               type => ''},
    {name => "uf",                      type => 'uc'},
    {name => "cep",                     type => 'cep'},
    {name => "ddd",                     type => 'int'},
    {name => "telefone1",               type => 'int'},
    {name => "telefone2",               type => 'int'},
    {name => "email",                   type => 'email'},
    {name => "eh_24h",                  type => 'bool'},
    {name => "horario_inicio",          type => 'time'},
    {name => "horario_fim",             type => 'time'},
    {name => "dias_funcionamento",      type => 'list', kind => 'dias'},
    {name => "eh_presencial",           type => 'bool'},
    {name => "eh_online",               type => 'bool'},
    {name => "funcionamento_pandemia",  type => 'bool'},
    {name => "observacao_pandemia",     type => ''},
    {name => "latitude",                type => 'num'},
    {name => "longitude",               type => 'num'},
    {name => "ja_passou_por_moderacao", type => 'bool'},
    {name => "existe_delegacia",        type => 'bool'},
    {name => "delegacia_mulher",        type => 'bool'},
    {name => "endereco_correto",        type => 'bool'},
    {name => "horario_correto",         type => 'bool'},
    {name => "telefone_correto",        type => 'bool'},
    {name => "observacao",              type => ''},
];

my $i       = 0;
my $col2idx = {map { $_->{name} => $i++ } @$headers};

print $fh2 "begin; delete from ponto_apoio where eh_importacao; \n";
my $accu = {};
$i = 0;
while (my $row = $csv->getline($fh)) {
    next if $i++ == 0;

    my $colidx = 0;
    my $insert = {};
    foreach my $header (@$headers) {
        my $name = $header->{name};
        my $val  = $row->[$colidx++];
        $val =~ s/^\s+//;
        $val =~ s/\s+$//;

        if ($header->{type} eq 'cep' && $val) {
            $val =~ /^\d{5}-?\d{3}$/ or die "$name na linha $i: $val nao se parece com um CEP válido\n";
            $val =~ s/-//;
        }
        elsif ($header->{type} eq 'uc' && $val) {
            $val = uc($val);
        }
        elsif ($header->{type} eq 'bool' && $val) {
            $val =~ /^(sim|n[ãa]o)$/i or die "$name na linha $i: $val nao se parece com um SIM/NÂO\n";
            $val =~ s/sim/1/i;
            $val =~ s/n[ãa]o/0/i;
        }
        elsif ($header->{type} eq 'int' && $val) {
            $val =~ /^\d+$/ia or die "$name na linha $i: $val nao se parece com inteiro\n";
        }
        elsif ($header->{type} eq 'num' && $val) {
            $val =~ /^-?\d+(\,\d+)?$/ia or die "$name na linha $i: $val nao se parece com número floating\n";
            $val =~ s/,/./;
        }
        elsif ($header->{type} eq 'ruanumero' && $val) {
            $val =~ s/s\/n//;
            if ($val) {
                $val =~ /^\d+$/ia or die "$name na linha $i: $val nao se parece com de rua\n";
            }
            $insert->{numero_sem_numero} = $val ? '0' : '1';
        }
        elsif ($header->{type} eq 'list' && $val) {
            my $kind = $header->{kind};
            my $fk   = $lists->{$kind};

            if (!exists $fk->{lc($val)}) {
                die "$name na linha $i: lc('$val') não existe na lista $kind";
            }
            else {
                $val = $fk->{lc($val)};
            }
        }

        $val = undef if $val eq '' && $header->{type} =~ /(int|num|bool)/;
        $insert->{$name} = $val;
    }

    for (qw/projeto uf categoria 24horas existe_delegacia verificado/) {
        $accu->{$_}{$insert->{$_} // '(NULL)'}++;
    }

    my @columns;
    my @values;
    while (my ($k, $v) = each %$insert) {
        next if $k eq 'projeto';

        push @columns, $k;
        if (defined $v) {
            my $quoted = $v;
            $quoted =~ s/'/\\'/g;
            push @values, "'$quoted'";
        }
        else {
            push @values, 'NULL';
        }
    }

    print $fh2 "insert into ponto_apoio (eh_importacao, status, " . join ', ', @columns;
    print $fh2 ") values ('1', 'active', " . join ', ',                          @values;
    print $fh2 ");\n";

    print $fh2 "insert into ponto_apoio2projetos (ponto_apoio_id, ponto_apoio_projeto_id) ";
    print $fh2 "values (LAST_INSERT_ID(), " . $insert->{projeto} . ");\n";

}
print $fh2 "commit;\n";

$csv->eof  or $csv->error_diag();
close $fh2 or die "$file.sql $!";
close $fh  or die "$file.csv: $!";

use DDP;
p $accu;