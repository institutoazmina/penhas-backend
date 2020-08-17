#<<<
use utf8;
package Penhas::Schema2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-05-12 05:19:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:etXYr4v+SR7+6RkpmDgX8A

use Carp;

sub sum_login_errors {
    my ($self, %opts) = @_;

    return $self->resultset('LoginErro')->search(
        {
            'created_at' => {'>' => DateTime->now->add(minutes => -60)->datetime(' ')},
            'cliente_id' => ($opts{cliente_id} or croak 'missing cliente_id'),
        }
    )->count();
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
