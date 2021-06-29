package Penhas::Utils;
use strict;
use warnings;
use JSON;
use v5.10;
use Mojo::URL;
use Crypt::PRNG qw(random_string random_string_from);
use Encode qw/encode_utf8/;
use Digest::SHA qw/sha256_hex/;
use Digest::MD5 qw/md5_hex/;
use File::Path qw(make_path);
use Carp;
use Time::HiRes qw//;
use Text::Xslate;
use POSIX ();
use utf8;
use vars qw(@ISA @EXPORT);

use DateTime::Format::Pg;

state $text_xslate = Text::Xslate->new(
    syntax => 'TTerse',
    module => ['Text::Xslate::Bridge::TT2Like'],
);

@ISA    = (qw(Exporter));
@EXPORT = qw(
  random_string
  random_string_from

  is_test
  env
  exec_tx_with_retry

  tt_test_condition
  tt_render

  cpf_hash_with_salt

  filename_cache_three
  get_media_filepath

  is_uuid_v4

  time_seconds_fmt

  trunc_to_meter

  pg_timestamp2iso_8601
  pg_timestamp2iso_8601_second
  db_epoch_to_etag
  pg_timestamp2human
  notifications_enabled
  check_password_or_die
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

    croak '$template is undef' unless defined $template;

    $template = "[% $template %]";
    my $ret = $text_xslate->render_string($template, $vars);
    $ret =~ /^\s+/;
    $ret =~ /\s+$/;

    #use DDP; p [$template, $vars, $ret];
    return $ret ? 1 : 0;
}

sub tt_render {
    my ($template, $vars) = @_;

    return '' unless $template;

    my $ret = $text_xslate->render_string($template, $vars);
    $ret =~ /^\s+/;
    $ret =~ /\s+$/;

    #use DDP; p [$template, $vars, $ret];
    return $ret;
}

sub cpf_hash_with_salt {
    my ($str) = shift;
    my $cpf_salt = $ENV{CPF_CACHE_HASH_SALT} or die 'CPF_CACHE_HASH_SALT is not defined';
    return sha256_hex($cpf_salt . encode_utf8($str));
}


sub filename_cache_three {
    my ($filename) = @_;

    my (@parts) = $filename =~ /^(..)(..)(...)/;

    return join('/', @parts);
}

sub get_media_filepath {
    my ($filename) = @_;

    my $path = $ENV{MEDIA_CACHE_DIR} . '/' . filename_cache_three($filename);

    make_path($path) unless -d $path;

    return join('/', $path, $filename);
}

sub is_uuid_v4 {
    $_[0] =~ /^[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i ? 1 : 0;
}

sub time_seconds_fmt {

    # nao mover isso pro começo, esse modulo se desliga sozinho no final do bloco
    use integer;
    return sprintf('%dm%02ds', $_[0] / 60 % 60, $_[0] % 60);
}

sub _nearest_floor {
    my $targ = abs(shift);
    my @res  = map { $targ * POSIX::ceil(($_ - 0.50000000000008 * $targ) / $targ) } @_;

    return wantarray ? @res : $res[0];
}

# semelhante a sprintf( '%0.5f', shift ) porem tem mais chance de cair em hit do cache
sub trunc_to_meter ($) {
    return &_nearest_floor(0.00009, shift);
}

sub pg_timestamp2iso_8601 {
    my ($timestamp) = @_;

    $timestamp =~ s/ /T/;
    $timestamp =~ s/\+.+$//;
    $timestamp =~ s/\..+$//;

    $timestamp .= 'Z';
    return $timestamp;
}

sub pg_timestamp2iso_8601_second {
    my ($timestamp) = @_;

    $timestamp =~ s/ /T/;
    $timestamp =~ s/\+.+$//;
    $timestamp =~ s/\..+$//;

    return $timestamp;
}

sub pg_timestamp2human {
    my ($timestamp) = @_;

    return '' unless $timestamp;

    $timestamp =~ s/Z$//;
    my $today   = DateTime->now->set_time_zone('America/Sao_Paulo')->dmy('/');
    my $is_date = $timestamp !~ /:/;
    $timestamp
      = DateTime::Format::Pg->parse_datetime(
        $is_date ? $timestamp : $timestamp =~ /\+/ ? $timestamp : $timestamp . '+00')
      ->set_time_zone('America/Sao_Paulo');

    $timestamp = $timestamp->dmy('/') . ($is_date ? '' : ' ' . $timestamp->hms(':'));

    $timestamp =~ s/$today/hoje/;
    return $timestamp;
}

sub db_epoch_to_etag {
    my ($timestamp) = @_;

    # remove timestamp
    $timestamp =~ s/\+\d+$//;

    die "$timestamp is not in expected format"
      unless $timestamp =~ /^2\d{3}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}(\.\d{1,8})?$/;

    return substr(md5_hex($timestamp), 0, 6) . '';
}

sub notifications_enabled {
    $ENV{NOTIFICATIONS_ENABLED} || 0;
}

sub check_password_or_die {
    my $pass = shift();

    if (!$pass || $pass =~ / $/ || $pass =~ /^ /) {
        die {
            error   => 'warning_space_password',
            message => 'A senha não pode iniciar ou terminar com espaço',
            field   => 'senha',
            reason  => 'invalid'
        };
    }

    if ($pass =~ /^(12345.*|picture1|password|111111.*|123123.*|senha)$/i) {
        die {
            error   => 'pass_too_weak',
            message => 'A senha utilizada é muito simples, utilize uma senha melhor.',
            field   => 'senha',
            reason  => 'invalid'
        };
    }
    my $txt = 'É necessário pelo menos 8 caracteres, pelo menos 1 letra, 1 número, e 1 carácter especial';

    if (length($pass) < 8) {
        die {
            error   => 'pass_too_weak/size',
            message => "A senha utilizada é muito curta! $txt",
            field   => 'senha',
            reason  => 'invalid'
        };
    }

    if ($pass !~ /[0-9]/) {
        die {
            error   => 'pass_too_weak/number',
            message => "A senha utilizada não usou números! $txt",
            field   => 'senha',
            reason  => 'invalid'
        };
    }

    if ($pass !~ /[A-Z]/i) {
        die {
            error   => 'pass_too_weak/letter',
            message => "A senha utilizada não usou letras! $txt",
            field   => 'senha',
            reason  => 'invalid'
        };
    }

    # se nao tem algo que é diferente de letra e numeros
    if ($pass !~ /[^0-9A-Z]/i) {
        die {
            error   => 'pass_too_weak/char',
            message => "A senha utilizada não usou caracteres especiais! $txt",
            field   => 'senha',
            reason  => 'invalid'
        };
    }

    return;
}

1;
