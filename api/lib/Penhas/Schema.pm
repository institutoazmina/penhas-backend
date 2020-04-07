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

use Crypt::OpenSSL::RSA;

sub get_rsa_keys {
    my ($self) = @_;

    my $pvt = delete $ENV{JWT_RSA_PVT_KEY};
    my $pub = delete $ENV{JWT_RSA_PUB_KEY};

    die 'ENV variables not loaded' unless ++$_variables_loaded;

    # Se não estiverem configuradas, vamos iniciar uma.
    if (!$pvt || !$pub) {

        my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);

        $pvt = $rsa->get_private_key_string;
        $pub = $rsa->get_public_key_string;

        $self->txn_do(
            sub {
                $self->storage->dbh->do(
                    <<'SQL_QUERY', undef,
                    INSERT INTO penhas_config ("name", "value") VALUES (?, ?), (?, ?)
                    ON CONFLICT (name)
                    WHERE valid_to = 'infinity'
                    DO UPDATE SET value = EXCLUDED.value;
SQL_QUERY
                    ('JWT_RSA_PUB_KEY', $pub, 'JWT_RSA_PVT_KEY', $pvt,)
                );
            }
        );
    }

    return (pub => $pub, pvt => $pvt);
}

use DateTime::Format::DateParse;

sub now {
    my $self = shift;

    my $now = $self->storage->dbh_do(
        sub {
            DateTime::Format::DateParse->parse_datetime($_[1]->selectrow_array('SELECT replaceable_now()'));
        }
    );

    return $now;
}

1;
