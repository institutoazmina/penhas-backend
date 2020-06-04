package Penhas::Controller::TickRSS;
use Mojo::Base 'Penhas::Controller';

use DateTime;

sub tick {
    my $c = shift;

    $c->tick_rss_feeds();

    return $c->render(
        text   => 'ok',
        status => 200,
    );
}


1;
