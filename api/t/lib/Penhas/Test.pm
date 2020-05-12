package Mojo::Transaction::Role::PrettyDebug {
    use Mojo::Base -role;
    use Mojo::Util 'term_escape';
    use DDP;

    use constant PRETTY => $ENV{TRACE} || $ENV{MOJO_CLIENT_PRETTY_DEBUG} || 0;

    after client_read => sub {
        my ($self, $chunk) = @_;
        my $url = $self->req->url->to_abs;
        my $err = $chunk =~ /1\.1\s[45]0/ ? '31' : '32';

        if (PRETTY) {
            my $tmp
              = $self->res->json && !$ENV{TRACE_JSON}
              ? $self->res->code . ' '
              . $self->res->message . "\n"
              . $self->res->headers->to_string() . "\n"
              . np($self->res->json, caller_info => 0)
              : term_escape($chunk);

            warn "\x{1b}[${err}m" . term_escape("-- Server response for $url\n") . $tmp . "\x{1b}[0m\n";


        }
    };

    around client_write => sub {
        my $orig  = shift;
        my $self  = shift;
        my $chunk = $self->$orig(@_);
        my $url   = $self->req->url->to_abs;
        warn "\x{1b}[32m" . term_escape("-- Client requesting $url...\n$chunk") . "\x{1b}[0m\n" if PRETTY;
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
use Digest::SHA qw/sha256_hex/;
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

    my $cpf_hash = sha256_hex($cpf);

    my $res = app->directus->search_one(
        table => 'clientes',
        form  => {'filter[cpf_hash][eq]' => $cpf_hash,}
    );
    use DDP;
    p $res;

    return $res;
}

sub get_cliente_by_email {

    my $res = app->directus->search_one(
        table => 'clientes',
        form  => {

            'filter[email][eq]' => shift,


        }
    );

    return $res;
}

sub get_forget_password_row {

    my $res = app->directus->search_one(
        table => 'clientes_reset_password',
        form  => {

            'filter[cliente_id][eq]' => shift,


        }
    );

    return $res;
}

sub get_user_session {
    my $random_cpf   = shift;
    my $random_email = 'email' . $random_cpf . '@something.com';

    my @other_fields = (
        raca        => 'pardo',
        apelido     => 'ca',
        app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
        dry         => 0,
    );

    get_schema->resultset('CpfCache')->find_or_create(
        {
            cpf_hashed  => cpf_hash_with_salt($random_cpf),
            dt_nasc     => '1994-01-31',
            nome_hashed => cpf_hash_with_salt(uc 'Quiz User Name'),
            situacao    => '',
        }
    );

    my $session;
    my $user_id;
    if (!cpf_already_exists($random_cpf)) {
        subtest_buffered 'Cadastro com sucesso' => sub {
            my $res = $t->post_ok(
                '/signup',
                form => {
                    nome_completo => 'Quiz User Name',
                    cpf           => $random_cpf,
                    email         => $random_email,
                    senha         => '123456',
                    cep           => '12345678',
                    dt_nasc       => '1994-01-31',
                    nome_social   => 'foobar lorem',
                    @other_fields,
                    genero => 'MulherTrans',
                },
            )->status_is(200)->tx->res->json;
            $session = $res->{session};
            $user_id = $res->{_test_only_id};
        };
    }
    else {
        my $res = $t->post_ok(
            '/login',
            form => {
                email       => $random_email,
                senha       => '123456',
                app_version => 'Versao Ios ou Android, Modelo Celular, Versao do App',
            }
        )->status_is(200)->tx->res->json;
        $session = $res->{session};
        $user_id = $res->{_test_only_id};
    }
    die 'missing session' unless $session;

    return ($session, $user_id);
}

sub user_cleanup {
    my (%opts) = @_;

    my $user_id = $opts{user_id};
    log_info("Apagando cliente $user_id");

    foreach my $table (
        qw/
        clientes_active_sessions
        clientes_quiz_session
        clientes_reset_password
        login_erros
        login_logs
        cliente_skills
        tweets
        tweets_likes
        tweets_reports
        /
      )
    {
        my $res = app->directus->search(
            table => $table,
            form  => {
                'filter[cliente_id][eq]' => $user_id,
                'fields'                 => 'id'
            }
        );
        my $ids = join ',', map { $_->{id} } $res->{data}->@*;
        if ($ids) {
            log_info("delete from $table where ids in $ids...");
            app->directus->delete(
                table => $table,
                id    => $ids
            );
        }
    }

    app->directus->delete(
        table => 'clientes',
        id    => $user_id
    );
}

1;
