package Penhas::Schema::Base;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime TimeStamp/);

1;

