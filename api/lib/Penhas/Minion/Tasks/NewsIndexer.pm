package Penhas::Minion::Tasks::NewsIndexer;
use Mojo::Base 'Mojolicious::Plugin';

use JSON;
use Penhas::Logger;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task( news_indexer => \&news_indexer);
}

sub news_indexer {
    my ($job, $news_id) = @_;

    log_trace("minion:news_indexer", $news_id);

    my $logger = $job->app->log;
    my $schema = $job->app->schema2;

    $schema->txn_do(
        sub {

            #$logger->info(sprintf 'Search for user product offer id=%d...', $user_product_offer_id);


        }
    );

    return $job->finish(1);
}

1;
