package Penhas::Helpers;
use common::sense;
use Penhas::SchemaConnected;
use Penhas::Directus;
use Penhas::Controller;
use Penhas::Helpers::CPF;
use Penhas::Helpers::Quiz;

use Carp qw/croak/;

sub setup {
    my $self = shift;

    Penhas::Helpers::Quiz::setup($self);
    Penhas::Helpers::CPF::setup($self);

    $self->helper(schema => sub { state $schema = Penhas::SchemaConnected->get_schema(@_) });

    $self->helper(
        remote_addr => sub {
            my $c = shift;

            foreach my $place (@{['cf-connecting-ip', 'x-real-ip', 'x-forwarded-for', 'tx']}) {
                if ($place eq 'cf-connecting-ip') {
                    my $ip = $c->req->headers->header('cf-connecting-ip');
                    return $ip if $ip;
                }
                elsif ($place eq 'x-real-ip') {
                    my $ip = $c->req->headers->header('X-Real-IP');
                    return $ip if $ip;
                }
                elsif ($place eq 'x-forwarded-for') {
                    my $ip = $c->req->headers->header('X-Forwarded-For');
                    return $ip if $ip;
                }
                elsif ($place eq 'tx') {
                    my $ip = $c->tx->remote_address;
                    return $ip if $ip;
                }
            }

            return;
        },
    );

    $self->helper('reply.exception' => sub { Penhas::Controller::reply_exception(@_) });
    $self->helper('reply.not_found' => sub { Penhas::Controller::reply_not_found(@_) });
    $self->helper('user_not_found'  => sub { Penhas::Controller::reply_not_found(@_, type => 'user_not_found') });

    $self->helper(directus => sub { Penhas::Directus->instance });

}


1;
