package Penhas::Helpers::Chat;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Penhas::Utils qw/is_test/;
use Mojo::Util qw/trim/;
use Scope::OnExit;
our $ForceFilterClientes;

our %activity_labels = (
    0  => 'há pouco tempo',
    1  => 'há poucos dias',
    2  => 'há poucos dias',
    3  => 'há poucos dias',
    4  => 'há alguns dias',
    5  => 'há alguns dias',
    6  => 'há alguns dias',
    7  => 'há alguns dias',
    8  => 'há algumas semanas',
    9  => 'há algumas semanas',
    10 => 'há algumas semanas',
    11 => 'há algumas semanas',
    12 => 'há algumas semanas',
    13 => 'há algumas semanas',
    14 => 'há algumas semanas',
);

sub setup {
    my $self = shift;

    $self->helper('chat_find_users' => sub { &chat_find_users(@_) });

}

sub chat_find_users {
    my ($c, %opts) = @_;

    my $user_obj = $opts{user_obj} or confess 'missing user_obj';
    my $rows     = $opts{rows} || 10;
    $rows = 10 if !is_test() && ($rows > 100 || $rows < 10);

    my $nome = trim(lc($opts{name} || ''));

    my $offset = 0;
    if ($opts{next_page}) {
        my $tmp = eval { $c->decode_jwt($opts{next_page}) };
        $c->reply_invalid_param('next_page')
          if ($tmp->{iss} || '') ne 'U:NP';
        $offset = $tmp->{offset};
    }

    my $rs = $c->schema2->resultset('Cliente')->search(
        {
            'me.modo_anonimo_ativo' => '0',
            'me.status'             => 'active',

            'me.genero' => {in => ['MulherTrans', 'Feminino']},    # &is_female()

            (
                $ForceFilterClientes
                ? ('me.id' => $ForceFilterClientes)
                : ()
            ),
        },
        {
            join => ['clientes_app_activities'],
            columns =>
              ['me.id', 'me.apelido', {activity => \"DATEDIFF( clientes_app_activities.last_tm_activity, now() )"}],
            order_by     => \'clientes_app_activities.last_tm_activity DESC',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            rows         => $rows + 1,
            offset       => $offset,
        }
    );

    if ($nome) {
        $rs = $rs->search(
            {
                '-or' => [
                    \['lower(me.nome_completo) like ?', "$nome%"],
                    \['lower(me.apelido) like ?',       "$nome%"],
                ],
            }
        );
    }

    my @rows      = $rs->all;
    my $cur_count = scalar @rows;
    my $has_more  = $cur_count > $rows ? 1 : 0;
    if ($has_more) {
        pop @rows;
        $cur_count--;
    }

    foreach (@rows) {
        $_->{activity} = $activity_labels{$_->{activity}} || 'há muito tempo';

    }

    my $next_page = $c->encode_jwt(
        {
            iss    => 'U:NP',
            offset => $offset + $cur_count,
        },
        1
    );

    return {
        rows      => \@rows,
        has_more  => $has_more,
        next_page => $has_more ? $next_page : undef,
    };
}

1;
