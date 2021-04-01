package Penhas::CEP;

use Moose;

with 'MooseX::Traits';

use Moose::Util::TypeConstraints qw(duck_type);
has '+_trait_namespace' => (default => __PACKAGE__);


sub find {
    my ($self, $cep, $trait) = @_;

    $cep =~ s/[^0-9]//go;
    $self->_find($cep);
}

1;
