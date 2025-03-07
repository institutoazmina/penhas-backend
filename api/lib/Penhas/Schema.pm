#<<<
use utf8;
package Penhas::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;
#>>>

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-04-07 18:53:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cNviansK5JMdNZUr7SVSwA

use Penhas::Logger;
my $_variables_loaded = 0;
use Penhas::Utils qw/random_string/;

sub get_jwt_key {
    my ($self) = @_;

    my $secret = delete $ENV{JWT_SECRET_KEY};
    die 'ENV variables not loaded' unless ++$_variables_loaded;
    # Se não estiverem configuradas, vamos iniciar uma.
    if (!$secret) {

        $secret = random_string(64);

        $self->txn_do(
            sub {
                $self->storage->dbh->do(
                    <<'SQL_QUERY', undef,
                    INSERT INTO penhas_config ("name", "value") VALUES (?, ?)
                    ON CONFLICT (name)
                    WHERE valid_to = 'infinity'
                    DO UPDATE SET value = EXCLUDED.value;
SQL_QUERY
                    ('JWT_SECRET_KEY', $secret,)
                );
            }
        );
    }

    return $secret;
}

use DateTime::Format::DateParse;

sub unaccent {
    my $self = shift;
    my $text = shift;
    return undef unless defined $text;
    return '' if $text eq '';
    return $self->storage->dbh_do(
        sub {
            $_[1]->selectrow_array('SELECT unaccent(?)', {}, $text);
        }
    );
}

1;
