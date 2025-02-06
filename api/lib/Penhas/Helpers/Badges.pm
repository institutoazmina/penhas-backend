package Penhas::Helpers::Badges;
use common::sense;
use Carp qw/confess/;
use utf8;

use Penhas::Logger;
use Penhas::Utils;

sub setup {
    my $self = shift;

    $self->helper('cliente_add_badge' => sub { &cliente_add_badge(@_) });

}

sub cliente_add_badge {
    my ($c, %opts) = @_;

    my $badge_id = $opts{badge_id} or confess 'missing badge_id';
    my $user     = $opts{user_obj} or confess 'missing user_obj';
    return {} unless $user->is_female();


    my $badge = $c->schema2->resultset('Badge')->find($badge_id);

    die {
        message => 'Badge não encontrada',
        error   => 'badge_not_found'
    } unless $badge;

    my $badge_cliente = $c->schema2->resultset('ClienteTag')->search(
        {
            badge_id    => $badge_id,
            cliente_id  => $user->id,
            valid_until => {'>' => \'now()'}
        }
    )->next;
    if (!$badge_cliente) {
        $c->schema2->txn_do(
            sub {
                $c->schema2->resultset('ClienteTag')->create(
                    {
                        badge_id    => $badge_id,
                        cliente_id  => $user->id,
                        created_on  => \'now()',
                        valid_until => 'infinity'
                    }
                );
            }
        );
    }

    return {};
}

1;
