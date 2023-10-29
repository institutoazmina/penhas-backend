package Penhas::CEP::Postmon;

use Moose::Role;
use feature 'state';

use Furl;
use JSON qw(decode_json);

sub name {'Postmon'}

sub _find {
    state $ua = Furl->new(timeout => 20);

    my $cep = pop;
    my $res = $ua->get('https://viacep.com.br/ws/' . $cep . '/json/');

    return unless $res->is_success;

    my $r = eval { decode_json($res->content) } or return;

    my $street = $r->{logradouro} || '';

    return {street => $street, city => $r->{localidade}, district => $r->{bairro}, state => $r->{uf},
        ibge => $r->{ibge}};
}

1;
