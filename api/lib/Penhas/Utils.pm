package Penhas::Utils;
use strict;
use warnings;
use JSON;
use v5.10;
use Mojo::URL;
use Crypt::PRNG qw(random_string random_string_from);

use Carp;
use Time::HiRes qw//;
use Text::Xslate;

use vars qw(@ISA @EXPORT);

@ISA    = (qw(Exporter));
@EXPORT = qw(
  random_string
  random_string_from

  is_test
  env
  exec_tx_with_retry

  tt_test_condition
);


sub is_test {
    if ($ENV{HARNESS_ACTIVE} || $0 =~ m{forkprove}) {
        return 1;
    }
    return 0;
}

sub env { return $ENV{${\shift}} }

sub exec_tx_with_retry {
    my ($some_tx, %opts) = @_;
    require Penhas::Logger;

    my $tries = $opts{tries} || 5;
    my $sleep = $opts{sleep} || 1;

  AGAIN:
    my $tx = $some_tx->();

    if ($tx->error) {
        my $err         = $tx->error;
        my $description = sprintf "Request %s %s code: %s response: %s", $tx->req->method,
          $tx->req->url->to_string, $err->{code}, $tx->res->body;

        if ($err->{code}) {
            Penhas::Logger::log_error($description);
            $tries = 0 if $err->{code} == 422 || $err->{code} >= 400 && $err->{code} <= 404;
        }
        else {
            Penhas::Logger::log_error("Connection error: $description $err->{message}");
        }

        if (--$tries > 0) {
            $sleep = ($sleep * 2) + rand($sleep / 2);
            $sleep = 15 if $sleep > 15;
            Penhas::Logger::log_error("Sleeping for $sleep seconds and trying again");
            Time::HiRes::sleep($sleep);
            goto AGAIN;
        }

        if ($err->{code}) {

            my $json = $tx->res->json;
            if ($err->{code} == 422 && $json->{error}{code} && $json->{error}{code} == 4) {
                die 'Invalid form: ' . $description . ' ' . $json->{error}{message};
            }
            die 'Request failed too many times: ' . $description;
        }
        else {
            die 'Cannot connect right now: ' . $description . ' ' . $err->{message};
        }
    }

    return $tx;
}

sub tt_test_condition {
    my ($template, $vars) = @_;
    state $tx = Text::Xslate->new(
        syntax => 'TTerse',
        module => ['Text::Xslate::Bridge::TT2Like'],
    );

    $template = "[% $template %]";
    my $ret = $tx->render_string($template, $vars);
    $ret =~ /^\s+/;
    $ret =~ /\s+$/;

    #use DDP; p [$template, $vars, $ret];
    return $ret ? 1 : 0;
}

1;
