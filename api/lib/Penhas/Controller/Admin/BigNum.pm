package Penhas::Controller::Admin::BigNum;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Penhas::Utils;
use DateTime;
use MooseX::Types::Email qw/EmailAddress/;
use Time::HiRes qw/tv_interval gettimeofday/;
use Crypt::JWT qw(encode_jwt decode_jwt);
use Mojo::URL;

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

    my @rows = (
        {name => 'Aplicativo PenhaS', resource => {dashboard => 4}, params => {}},
        {name => 'Twitter Penha',     resource => {dashboard => 5}, params => {}},
    );
    my $metabase_secret = $ENV{METABASE_SECRET} || 'secret';
    my @ret             = ();
    foreach my $payload (@rows) {
        $payload->{_}{admin_user} = $c->stash('admin_user')->id;
        $payload->{exp} = time() + 3600;                           # 1 hour

        my $jwt = encode_jwt(
            alg     => 'HS256',
            key     => $metabase_secret,
            payload => $payload
        );
        my $url = Mojo::URL->new('https://analytics.penhas.com.br/');
        $url->path('/embed/dashboard/' . $jwt);
        $url->fragment('bordered=false&titled=false');

        push @ret, {
            name => $payload->{name},
            url  => $url->to_string(),
        };
    }

    return $c->respond_to_if_web(
        json => {
            json => {
                results => \@results,
                reports => \@ret,
            }
        },
        html => {
            results => \@results,
            reports => \@ret,

        },
    );
}


1;
