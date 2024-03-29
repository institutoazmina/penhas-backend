package Penhas::SchemaConnected;
use common::sense;
use FindBin qw($RealBin);
use Config::General;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(get_schema get_connect_info get_schema2);
my $schema_instance;
my $schema2_instance;

use Mojo::Pg;
use Penhas::Schema;
use Penhas::Schema2;
use Penhas::Logger;

sub get_connect_info {
    my $host     = $ENV{POSTGRESQL_HOST}     || 'localhost';
    my $port     = $ENV{POSTGRESQL_PORT}     || 5432;
    my $user     = $ENV{POSTGRESQL_USER}     || 'postgres';
    my $password = $ENV{POSTGRESQL_PASSWORD} || 'Penhas-pass';
    my $dbname   = $ENV{POSTGRESQL_DBNAME}   || 'penhas_dev';

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

    my $confs = $dbh->selectall_arrayref(
        'select "name", "value" from penhas_config where valid_to = \'infinity\'',
        {Slice => {}}
    );

    foreach my $kv (@$confs) {
        my ($k, $v) = ($kv->{name}, $kv->{value});
        $ENV{$k} = $v;
    }

    print STDERR "Loaded " . scalar @$confs . " envs\n";

    $ENV{REDIS_NS} ||= '';

    if (!$ENV{CPF_CACHE_HASH_SALT}) {
        die 'Missing CPF_CACHE_HASH_SALT';
    }

    $ENV{MEDIA_HASH_SALT} ||= $ENV{CPF_CACHE_HASH_SALT} . '.media';
    $ENV{NEWS_HASH_SALT}  ||= $ENV{CPF_CACHE_HASH_SALT} . '.news';
    $ENV{GUARD_HASH_SALT} ||= $ENV{CPF_CACHE_HASH_SALT} . '.guard';

    die 'missing PUBLIC_API_URL' unless $ENV{PUBLIC_API_URL};
    $ENV{PUBLIC_API_URL} .= '/'  unless $ENV{PUBLIC_API_URL} =~ /\/$/;

    $ENV{MEDIA_CACHE_DIR} = '/tmp' unless -d $ENV{MEDIA_CACHE_DIR};

    $ENV{MEDIA_ERR_DIR} = '/tmp' unless -d $ENV{MEDIA_ERR_DIR};

    $ENV{TMP_AUDIO_DIR} = '/tmp' unless -d $ENV{TMP_AUDIO_DIR};

    $ENV{PONTO_APOIO_CACHE_DIR} = '/tmp' unless -d $ENV{PONTO_APOIO_CACHE_DIR};

    if ($ENV{TMP_AUDIO_DIR} =~ q|^/tmp|) {
        $ENV{TMP_AUDIO_DIR} = '/tmp/audios';
        mkdir $ENV{TMP_AUDIO_DIR} unless -d $ENV{TMP_AUDIO_DIR};
    }


    undef $Penhas::Logger::instance;

    $schema_instance = $schema;
    return $schema_instance;
}


sub get_connect_info2 {
    my $host     = $ENV{POSTGRESQL_HOST}     || 'localhost';
    my $port     = $ENV{POSTGRESQL_PORT}     || 5432;
    my $user     = $ENV{POSTGRESQL_USER}     || 'postgres';
    my $password = $ENV{POSTGRESQL_PASSWORD} || 'Penhas-pass';
    my $dbname   = $ENV{POSTGRESQL_DBNAME}   || 'Penhas';

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

sub get_schema2 {
    return $schema2_instance if $schema2_instance;

    my $schema = Penhas::Schema2->connect(get_connect_info2());

    my $dbh = $schema->storage->dbh;

    $schema2_instance = $schema;
    return $schema2_instance;
}

# conexao pro minion
sub get_mojo_pg {
    state $pg = Mojo::Pg->new(
        sprintf(
            'postgresql://%s:%s@%s:%s/%s',
            $ENV{POSTGRESQL_USER}     || 'postgres',
            $ENV{POSTGRESQL_PASSWORD} || 'Penhas-pass',
            $ENV{POSTGRESQL_HOST}     || 'localhost',
            $ENV{POSTGRESQL_PORT}     || 5432,
            $ENV{POSTGRESQL_DBNAME}   || 'penhas_dev',
        )
    );
    return $pg;
}


1;
