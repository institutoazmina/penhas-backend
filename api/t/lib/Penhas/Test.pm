package Mojo::Transaction::Role::PrettyDebug {
    use Mojo::Base -role;
    use Mojo::Util 'term_escape';

    use constant PRETTY => $ENV{TRACE} || $ENV{MOJO_CLIENT_PRETTY_DEBUG} || 0;

    after client_read => sub {
        my ($self, $chunk) = @_;
        my $url = $self->req->url->to_abs;
        my $err = $chunk =~ /1\.1\s[45]0/ ? '31' : '32';
        warn "\x{1b}[${err}m" . term_escape("-- Client <<< Server ($url)\n$chunk") . "\x{1b}[0m\n" if PRETTY;
    };

    around client_write => sub {
        my $orig  = shift;
        my $self  = shift;
        my $chunk = $self->$orig(@_);
        my $url   = $self->req->url->to_abs;
        warn "\x{1b}[32m" . term_escape("-- Client >>> Server ($url)\n$chunk") . "\x{1b}[0m\n" if PRETTY;
        return $chunk;
    };
};

package Penhas::Test;
use Mojo::Base -strict;
use Test2::V0;
use Test2::Tools::Subtest qw(subtest_buffered subtest_streamed);
use Test2::Mock;
use Test::Mojo;
use Penhas::Logger;

my $redis_ns;

sub END {
    if (defined $redis_ns) {
        my $redis = Penhas::KeyValueStorage->instance->redis;
        my @del   = $redis->keys($redis_ns . '*');
        $redis->del(@del) if @del;
    }
}

use DateTime;
use Penhas::Utils;
use Data::Fake qw/ Core Company Dates Internet Names Text /;
use Data::Printer;
use Mojo::Util qw(monkey_patch);
use JSON;
use Mojo::JSON qw(true false);
use Scope::OnExit;
our @trace_logs;

sub trace_popall {
    my @list = @trace_logs;

    @trace_logs = ();

    return join ',', @list;
}

sub import {
    strict->import;

    $ENV{DIRECUTS_API_TOKEN}  = 'SSzNpkUCVo1g2G4JxL5MnaM6';
    $ENV{DISABLE_RPS_LIMITER} = 1;
    srand(time() ^ ($$ + ($$ << 15)));
    $redis_ns = $ENV{REDIS_NS} = 'TEST_NS:' . int(rand() * 100000) . '__';
    no strict 'refs';

    my $caller = caller;

    while (my ($name, $symbol) = each %{__PACKAGE__ . '::'}) {
        next if $name eq 'BEGIN';
        next if $name eq 'import';
        next unless *{$symbol}{CODE};

        my $imported = $caller . '::' . $name;
        *{$imported} = \*{$symbol};
    }
}

my $t = Test::Mojo->with_roles('+StopOnFail')->new('Penhas');
$t->ua->on(
    start => sub {
        my ($ua, $tx) = @_;
        $tx->with_roles('Mojo::Transaction::Role::PrettyDebug');
    }
);

sub test_instance {$t}
sub t             {$t}

sub app { $t->app }

sub get_schema { $t->app->schema }

sub resultset { get_schema->resultset(@_) }

sub db_transaction (&) {
    my ($code) = @_;

    my $schema = get_schema;
    eval {
        $schema->txn_do(
            sub {
                $code->();
                die "rollback\n";
            }
        );
    };
    die $@ unless $@ =~ m{rollback};
}

sub cpf_already_exists {
    my ($cpf) = @_;

    # por enquanto, precisa ir buscar lá no banco do MYSQL
    return 0;
}


1;
