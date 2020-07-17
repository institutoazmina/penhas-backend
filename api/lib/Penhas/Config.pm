package Penhas::Config;
use common::sense;

sub setup {
    my $app = shift;

    $app->defaults(layout => 'padrao', title => 'default');

    # Hypnotoad.
    my $api_port      = int($ENV{API_PORT});
    my $api_workers   = int($ENV{API_WORKERS});
    my $spare_workers = int($api_workers / 2);


    $api_workers   = 1 if $api_workers < 1;
    $spare_workers = 1 if $spare_workers < 1;

    $app->config->{hypnotoad} = {
        workers           => $api_workers,
        spare             => $spare_workers,
        listen            => ["http://*:${api_port}"],
        proxy             => 1,
        graceful_timeout  => 600,
        heartbeat_timeout => 60,
    };
}

1;
