package Penhas::Controller::Admin::BigNum;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Penhas::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Time::HiRes qw/tv_interval gettimeofday/;

sub abignum_get {
    my $c = shift;
    $c->stash(
        template => 'admin/big_num',
    );

    my $rs = $c->schema2->resultset('AdminBigNumber')->search(
        {
            status => 'published',
        },
        {
            order_by     => 'sort',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    );
    my @results;

    my $t0 = [gettimeofday];

    while (my $r = $rs->next) {
        my ($column1) = $c->schema2->storage->dbh->selectrow_array($r->{sql});

        $r->{number} = $column1;
        push @results, $r;
    }
    $c->stash(elapsed => tv_interval($t0));

    return $c->respond_to_if_web(
        json => {
            json => {
                results => \@results,
            }
        },
        html => {
            results => \@results,
        },
    );
}


1;
