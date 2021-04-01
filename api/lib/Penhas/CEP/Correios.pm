package Penhas::CEP::Correios;

use Moose::Role;
use WWW::Correios::CEP;
use feature 'state';

sub name {'Correios'}

sub _find {
    state $cepper = WWW::Correios::CEP->new({post_content => 'tipoCEP=ALL&semelhante=N&relaxation='});
    my $r = $cepper->find(pop);

    return if defined $r && ref $r eq 'HASH' && exists $r->{status} && $r->{status} =~ /erro/i;

    my $cep = $r->{cep};
    $cep =~ s/[^0-9]//g;

    return {
        street   => $r->{street},
        cep      => $cep,
        city     => $r->{location},
        district => $r->{neighborhood},
        state    => $r->{uf},
    };
}

1;
