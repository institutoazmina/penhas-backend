package MojoX::InsistentPromise;
use strict;
use Carp;
use Mojo::IOLoop;
use Mojo::Promise;

my @retry_timing = (0, 0.5, 1, 3, 7, 7, 13, 13);

use Scalar::Util 'weaken';

sub new {
    my $class = shift;

    my %opts = @_;

    croak 'missing option init' unless $opts{init};

    croak 'missing option check_sucess' unless $opts{check_sucess};

    my $self = bless {
        init         => $opts{init},
        check_sucess => $opts{check_sucess},

        id    => exists $opts{id}           ? $opts{id}           : undef,
        retry => exists $opts{retry_timing} ? $opts{retry_timing} : \@retry_timing,

        should_continue => $opts{should_continue} ? $opts{should_continue} : sub {1},

        max_fail   => exists $opts{max_fail} ? $opts{max_fail} : 100,
        fail_count => 0,
    };

    my $ip = Mojo::Promise->new;
    $self->{promise} = $ip;

    my $inner_p = $self->{init}->($self->{id});
    $inner_p->then($self->_success_cb())->catch($self->_fail_cb());

    return ($self, $self->{promise});
}

sub _exp_retry_fail {
    my $self  = shift;
    my $value = $self->{retry}->[$self->{fail_count} - 1];
    $value = $self->{retry}[-1] || 15 if !defined $value;

    my $jitter = rand($value / 2);
    return $jitter + $value;
}

sub _success_cb {
    my ($self) = @_;

    return sub {
        my ($response) = @_;

        if (defined $response && $self->{check_sucess}->($response, $self->{id})) {
            $self->{promise}->resolve($response);
        }
        else {

            $self->{fail_count} = $self->{fail_count} + 1;

            if (defined $response && $self->{fail_count} < $self->{max_fail}) {
                my $exp_retry = $self->_exp_retry_fail();

                my $inner_p = $self->{init}->($self->{id});

                Mojo::IOLoop->timer(
                    $exp_retry => sub {
                        $inner_p->then($self->_success_cb())->catch($self->_fail_cb());
                    }
                );

            }
            else {
                $self->{promise}->reject('max_fail reached', $self->{id}, $response);
            }

        }

        return undef;
    }
}

sub _fail_cb {
    my ($self) = @_;

    return sub {
        my ($err) = @_;

        if ($self->{should_continue}($err)) {

            $self->{fail_count} = $self->{fail_count} + 1;

            if ($self->{fail_count} < $self->{max_fail}) {
                my $exp_retry = $self->_exp_retry_fail();
                Mojo::IOLoop->timer(
                    $exp_retry => sub {
                        my $inner_p = $self->{init}->($self->{id});
                        $inner_p->then($self->_success_cb())->catch($self->_fail_cb());
                    }
                );
            }
            else {
                $self->{promise}->reject('toomanyexceptions', $self->{id}, $err);
            }
        }
        else {
            $self->{promise}->reject('Aborted due to should_continue=false, id=' . $self->{id}, $err);
        }

        return undef;
    };

}


1;
