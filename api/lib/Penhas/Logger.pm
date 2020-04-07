package Penhas::Logger;
use strict;
use warnings;

use DateTime;
use IO::Handle;
use Log::Log4perl qw(:levels);
use Penhas::Utils qw(is_test);

our @ISA = qw(Exporter);

our @EXPORT = qw(
  log_info log_fatal log_error get_logger log_trace log_warn log_debug
  slog_info slog_fatal slog_error slog_trace slog_warn slog_debug
);

our $instance;

sub get_logger {

    return $instance if $instance;

    my $test_is_folder;
    if (@ARGV) {
        $test_is_folder = $ARGV[-1] eq 't' || $ARGV[-1] eq 't/' || $ARGV[-1] eq './t' || $ARGV[-1] eq './t/';
    }

    if ($ENV{PENHAS_API_LOG_DIR}) {
        if (-d $ENV{PENHAS_API_LOG_DIR}) {
            my $date_now = DateTime->now->ymd('-');

            # vai ter q rever isso, quando é mojo..
            my $app_type = $0 =~ /\.psgi/ ? 'api' : &_extract_basename($0);

            my $log_file = $app_type eq 'api' ? "api.$date_now.$$" : "$app_type.$date_now";

            $ENV{PENHAS_API_LOG_DIR} = $ENV{PENHAS_API_LOG_DIR} . "/$log_file.log";
            print STDERR "Redirecting STDERR/STDOUT to $ENV{PENHAS_API_LOG_DIR}\n";
            close(STDERR);
            close(STDOUT);
            autoflush STDERR 1;
            autoflush STDOUT 1;
            open(STDERR, '>>', $ENV{PENHAS_API_LOG_DIR}) or die 'cannot redirect STDERR';
            open(STDOUT, '>>', $ENV{PENHAS_API_LOG_DIR}) or die 'cannot redirect STDOUT';

        }
        else {
            print STDERR "PENHAS_API_LOG_DIR is not a dir\n";
        }
    }
    else {
        print STDERR "PENHAS_API_LOG_DIR not configured\n";
    }

    Log::Log4perl->easy_init(
        {
            level => $DEBUG,
            layout =>
              (is_test() && $test_is_folder ? '' : '[%d{dd/MM/yyyy HH:mm:ss.SSS}] [%p{4} %P] %x %m{indent=1}%n'),
            ($ENV{PENHAS_API_LOG_DIR} ? (file => '>>' . $ENV{PENHAS_API_LOG_DIR}) : ()),
            'utf8'    => 1,
            autoflush => 1,

        }
    );

    return $instance = Log::Log4perl::get_logger;
}

# logs
sub log_info {
    my (@texts) = @_;
    get_logger()->info(join ' ', @texts);
}

sub log_warn {
    my (@texts) = @_;
    get_logger()->warn(join ' ', @texts);
}

sub log_error {
    my (@texts) = @_;
    get_logger()->error(join ' ', @texts);
}

sub log_fatal {
    my (@texts) = @_;
    get_logger()->fatal(join ' ', @texts);
}

sub log_debug {
    my (@texts) = @_;
    get_logger()->debug(join ' ', @texts);
}


sub slog_info {
    get_logger()->info(sprintf shift(), @_);
}

sub slog_warn {
    get_logger()->warn(sprintf shift(), @_);
}

sub slog_error {
    get_logger()->error(sprintf shift(), @_);
}

sub slog_fatal {
    get_logger()->fatal(sprintf shift(), @_);
}

sub slog_debug {
    get_logger()->debug(sprintf shift(), @_);
}


sub _extract_basename {
    my ($path) = @_;
    my ($part) = $path =~ /.+(?:\/(.+))$/;
    return lc($part);
}

sub log_trace {
    return unless is_test();

    push @Penhas::Test::trace_logs, @_;
}

1;
