package Penhas::SchemaConnected;
use common::sense;
use FindBin qw($RealBin);
use Config::General;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(get_schema get_connect_info);
my $schema_instance;

use Penhas::Schema;
use Penhas::Logger;

sub get_connect_info {
    my $host     = $ENV{POSTGRESQL_HOST}     || 'localhost';
    my $port     = $ENV{POSTGRESQL_PORT}     || 5432;
    my $user     = $ENV{POSTGRESQL_USER}     || 'postgres';
    my $password = $ENV{POSTGRESQL_PASSWORD} || 'Penhas-pass';
    my $dbname   = $ENV{POSTGRESQL_DBNAME}   || 'Penhas';

    sub _extract_basename {
        my ($path) = @_;
        my ($part) = $path =~ /.+(?:\/(.+))$/;
        return lc($part);
    }

    my $app_name = ($ENV{APP_NAME} || '') . ' ' . &_extract_basename($0) . ' ' . $$;

    $app_name =~ s/[^A-Z0-9\- ]//g;

    return {
        dsn               => "dbi:Pg:dbname=$dbname;host=$host;port=$port",
        user              => $user,
        password          => $password,
        AutoCommit        => 1,
        quote_char        => "\"",
        name_sep          => ".",
        auto_savepoint    => 1,
        pg_server_prepare => $ENV{HARNESS_ACTIVE} || $0 =~ m{forkprove} ? 0 : 1,
        pg_enable_utf8    => 1,
        "on_connect_do"   => [
            "SET client_encoding=UTF8",
            "SET TIME ZONE 'UTC'",
            "SET application_name TO '$app_name'"
        ]
    };
}

sub get_schema {
    return $schema_instance if $schema_instance;

    my $schema = Penhas::Schema->connect(get_connect_info());

    my $dbh = $schema->storage->dbh;

    my $confs
      = $dbh->selectall_arrayref('select "name", "value" from penhas_config where valid_to = \'infinity\'', {Slice => {}});

    foreach my $kv (@$confs) {
        my ($k, $v) = ($kv->{name}, $kv->{value});
        $ENV{$k} = $v;
    }

    print STDERR "Loaded " . scalar @$confs . " envs\n";

    $ENV{REDIS_NS} ||= '';

    undef $Penhas::Logger::instance;

    $schema_instance = $schema;
    return $schema_instance;
}

1;
