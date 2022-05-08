use strict;
use Email::Valid;
use utf8;
use DateTime;

use JSON::XS;
use Text::CSV_XS;
use open qw/:std :utf8/;

use DDP;

my $file = $ARGV[0];

my $csv = Text::CSV_XS->new({binary => 1, sep_char => ','})
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
            'ong'              => 'ong'
        }
    ],
    [
        rua => {
            Rodovia         => 'Rodovia',
            Rua             => 'Rua',
            Avenida         => 'Avenida',
            Estrada         => 'Estrada',
            Alameda         => 'Alameda',
            Viela           => 'Viela',
            Via             => 'Via',
            Travessa        => 'Travessa',
            Quadra          => 'Quadra',
            Praça           => 'Praça',
            Área            => 'Área',
            Conjunto        => 'Conjunto',
            Villa           => 'Vila',
            Vila            => 'Vila',
            'Sítio'         => 'Sítio',
            'Área Especial' => 'Área Especial',
            'Trecho'        => 'Trecho',
            'Setor'         => 'Setor',
            Entrequadra     => 'Entrequadra',

        }
    ],
    [
        dias => {
            'Dias úteis'                                => 'dias_uteis',
            'Fim de semana'                             => 'fds',
            'Dias úteis com plantão aos fins de semana' => 'dias_uteis_fds_plantao',
            'Todos os dias'                             => 'todos_os_dias',
            'Segunda a sábado'                          => 'seg_a_sab',
            'Segunda a quinta'                          => 'seg_a_qui',
            'Terça a quinta'                            => 'ter_a_qui',
            'Quintas-feiras'                            => 'quinta_feira'
        }
    ],
    [
        abrangencia => {
            Local       => 'Local',
            Regional    => 'Regional',
            'Regional?' => 'Regional',
            'Nacional'  => 'Nacional',
        }
    ]
};
$lists->{projeto} = {
    mapa_delegacia            => 2,
    penhas                    => '1',
    'mapa_delegacias, penhas' => '1,2'
};

=pod
alter table ponto_apoio add column abrangencia  varchar not null;
alter table ponto_apoio add column eh_whatsapp  boolean not null  default false;
alter table ponto_apoio add column ramal1  bigint;
alter table ponto_apoio add column ramal2  bigint;
alter table ponto_apoio add column cod_ibge  bigint;
alter table ponto_apoio add column fonte  character varying;



delete from public.ponto_apoio_categoria;

INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (8, 'prod', '2020-07-31 11:48:36+00', 'Casa da Mulher Brasileira', '#5D82FA', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (9, 'prod', '2020-07-31 11:48:45+00', 'Posto de Atendimento em delegacia comum', '#CB8BD9', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (568, 'prod', '2020-09-22 04:49:02+00', 'Delegacia Comum', '#607D8B', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (5, 'prod', '2020-07-31 11:48:05+00', 'Delegacia da Mulher', '#F982B4', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (576, 'prod', NULL, 'Assistência Social', '#5D82FA', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (577, 'prod', NULL, 'Centro de Referência da Mulher', '#A7C1B4', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (578, 'prod', NULL, 'Ouvidoria', '#607D8B', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (579, 'prod', NULL, 'Saúde', '#00BCD4', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (580, 'prod', NULL, 'Segurança Pública', '#F982B4', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (581, 'prod', NULL, 'Serviço online', '#F9CA62', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (582, 'prod', NULL, 'Sociedade Civil Organizada', '#CB8BD9', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (583, 'prod', NULL, 'Jurídico', '#9C27B0', NULL);
INSERT INTO public.ponto_apoio_categoria (id, status, created_on, label, color, owner) VALUES (584, 'prod', NULL, 'Direitos Humanos', '#80D1F9', NULL);

SELECT pg_catalog.setval('public.ponto_apoio_categoria_id_seq', 584, true);

ALTER TABLE ONLY public.ponto_apoio_categoria
    ADD CONSTRAINT idx_26416_primary PRIMARY KEY (id);

CREATE TABLE public.ponto_apoio2projetos (
    ponto_apoio_id integer NOT NULL,
    ponto_apoio_projeto_id integer NOT NULL
);
ALTER TABLE ONLY public.ponto_apoio2projetos
    ADD CONSTRAINT ponto_apoio2projetos_pkey PRIMARY KEY (ponto_apoio_id, ponto_apoio_projeto_id);

ALTER TABLE ONLY public.ponto_apoio2projetos
    ADD CONSTRAINT ponto_apoio2projetos_ponto_apoio_id_fkey FOREIGN KEY (ponto_apoio_id) REFERENCES public.ponto_apoio(id);
ALTER TABLE ONLY public.ponto_apoio2projetos
    ADD CONSTRAINT ponto_apoio2projetos_ponto_apoio_projeto_id_fkey FOREIGN KEY (ponto_apoio_projeto_id) REFERENCES public.ponto_apoio_projeto(id);




=cut

$lists->{categoria} = {
    'casa da mulher brasileira'               => 8,
    'posto de atendimento em delegacia comum' => 9,
    'delegacia comum'                         => 568,
    'delegacia da mulher'                     => 5,
    'assistência social'                      => 576,
    'centro de referência da mulher'          => 577,
    'ouvidoria'                               => 578,
    'saúde'                                   => 579,
    'segurança pública'                       => 580,
    'serviço online'                          => 581,
    'sociedade civil organizada'              => 582,
    'jurídico'                                => 583,
    'direitos humanos'                        => 584,
};

my $headers = [

    {name => 'id_estabelecimento', type => ''},
    {name => 'projeto',                type => 'list', kind => 'projeto'},
    {name => 'fonte',                  type => ''},                               #novo
    {name => 'nome',                   type => ''},
    {name => 'sigla',                  type => 'uc'},
    {name => 'natureza',               type => 'list', kind => 'natureza'},
    {name => 'categoria',              type => 'list', kind => 'categoria'},
    {name => 'abrangencia',            type => 'list', kind => 'abrangencia'},    # novo
    {name => 'descricao',              type => ''},                               # novo
    {name => 'tipo_logradouro',        type => 'list', kind => 'rua'},
    {name => 'nome_logradouro',        type => ''},
    {name => 'numero',                 type => 'ruanumero'},
    {name => 'numero_sem_numero',      type => 'bool'},
    {name => 'complemento',            type => ''},
    {name => 'bairro',                 type => ''},
    {name => 'municipio',              type => ''},
    {name => 'cod_ibge',               type => 'int'},                            # novo
    {name => 'uf',                     type => 'uc'},
    {name => 'cep',                    type => 'cep'},
    {name => 'ddd',                    type => 'int'},
    {name => 'telefone1',              type => 'tel'},
    {name => 'ramal1',                 type => 'int'},                            # novo
    {name => 'telefone2',              type => 'tel'},
    {name => 'ramal2',                 type => 'int'},                            # novo
    {name => 'eh_whatsapp',            type => 'bool'},                           # novo
    {name => 'email',                  type => 'email'},
    {name => 'eh_24h',                 type => 'bool'},
    {name => 'horario_inicio',         type => 'time'},
    {name => 'horario_fim',            type => 'time'},
    {name => 'dias_funcionamento',     type => 'list', kind => 'dias'},
    {name => 'eh_presencial',          type => 'bool'},
    {name => 'eh_online',              type => 'bool'},
    {name => 'funcionamento_pandemia', type => 'bool'},
    {name => 'observacao_pandemia',    type => ''},
    {name => 'latitude',               type => 'num'},
    {name => 'longitude',              type => 'num'},
    {name => 'observacao',             type => ''},
];

my $i       = 0;
my $col2idx = {map { $_->{name} => $i++ } @$headers};

print $fh2 "begin; delete from ponto_apoio where eh_importacao; \n";
my $accu = {};
$i = 0;
LINE:
while (my $row = $csv->getline($fh)) {
    next if $i++ == 0;


    my $colidx = 0;
    my $insert = {};
    foreach my $header (@$headers) {
        my $name = $header->{name};
        my $val  = $row->[$colidx++];
        $val =~ s/^\s+//;
        $val =~ s/\s+$//;

        if ($name eq 'natureza' && $val eq 'tirar') {
            print STDERR "pulando linha $i\n";
            next LINE;
        }

        if ($header->{type} eq 'cep' && $val) {
            $val =~ /^\d{5}-?\d{3}$/
              or die "$name na linha $i: $val nao se parece com um CEP válido\n";
            $val =~ s/-//;
        }
        elsif ($header->{type} eq 'uc' && $val) {
            $val = uc($val);
        }
        elsif ($header->{type} eq 'bool' && $val) {
            $val =~ /^(sim|n[ãa]o)$/i
              or die "$name na linha $i: $val nao se parece com um SIM/NÂO\n";
            $val =~ s/sim/1/i;
            $val =~ s/n[ãa]o/0/i;
        }
        elsif ($header->{type} eq 'int' && $val) {
            $val =~ /^\d+$/ia
              or die "$name na linha $i: $val nao se parece com inteiro\n";
        }
        elsif ($header->{type} eq 'tel' && $val) {

            $val =~ s/^(\d{4})[-\s](\d{4})$/$1$2/;

            $val =~ /^\d+$/ia
              or die "$name na linha $i: $val nao se parece com inteiro\n";
        }
        elsif ($header->{type} eq 'num' && $val) {
            $val =~ /^-?\d+(\,\d+)?$/ia
              or die "$name na linha $i: $val nao se parece com número floating\n";
            $val =~ s/,/./;
        }
        elsif ($header->{type} eq 'ruanumero' && $val) {
            $val =~ s/s\/n//;
            if ($val) {
                $val =~ /^\d+$/ia
                  or die "$name na linha $i: $val nao se parece com de rua\n";
            }
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
        elsif ($header->{type} eq 'time' && $val) {
            $val =~ s/^(\d\d\:\d\d)\:00$/$1/;
            $val =~ /^\d\d:\d\d$/a
              or die "$name na linha $i: $val nao se parece com horário\n";
        }
        elsif ($header->{type} eq 'email' && $val) {
            $val =~ /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/ai
              or die "$name na linha $i: $val nao se parece com e-mail\n";
        }
        elsif ($header->{type} eq '') {

            # not op
        }
        elsif ($val) {
            die "Missing " . $header->{type};

        }

        $val = undef if $val eq '' && $header->{type} =~ /(int|num|bool|time|tel)/;
        $insert->{$name} = $val;
    }

    for (qw/projeto uf categoria eh_24h natureza abrangencia/) {
        $accu->{$_}{$insert->{$_} // '(NULL)'}++;
    }

    my @columns;
    my @values;
    $insert->{numero_sem_numero} = $insert->{numero}      ? '0' : '1';
    $insert->{eh_whatsapp}       = $insert->{eh_whatsapp} ? '1' : '0';

    for my $k (sort keys %$insert) {
        next if $k eq 'projeto';
        next if $k eq 'id_estabelecimento';
        my $v = $insert->{$k};

        push @columns, $k;
        if (defined $v) {
            my $quoted = $v;
            push @values, "\$token\$$quoted\$token\$";
        }
        else {
            push @values, 'NULL';
        }
    }

    print $fh2 "insert into ponto_apoio (created_on,updated_at, eh_importacao, status, " . join ', ',
      @columns;
    print $fh2 ") values (now(),now(),'1', 'active', " . join ', ', @values;
    print $fh2 ");\n";

    foreach (split ',', $insert->{projeto}) {

        print $fh2 "insert into ponto_apoio2projetos (ponto_apoio_id, ponto_apoio_projeto_id)";
        print $fh2 "values (currval(pg_get_serial_sequence('ponto_apoio','id')), " . $_ . ");\n";
    }

}
print $fh2 "commit;\n";

$csv->eof  or $csv->error_diag();
close $fh2 or die "$file.sql $!";
close $fh  or die "$file.csv: $!";

use DDP;
p $accu;
