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

    $self->helper('chat_find_users'   => sub { &chat_find_users(@_) });
    $self->helper('chat_profile_user' => sub { &chat_profile_user(@_) });


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

    my $rs = $c->schema2->resultset('ClientesAppActivity')->search(
        {
            'cliente.modo_anonimo_ativo' => '0',
            'cliente.status'             => 'active',

            'cliente.genero' => {in => ['MulherTrans', 'Feminino']},    # equivalente ao &is_female()

            (
                $ForceFilterClientes
                ? ('me.cliente_id' => {'in' => $ForceFilterClientes})
                : ()
            ),
        },
        {
            join    => [{'cliente' => {'cliente_skills' => 'skill'}}],
            columns => [
                {cliente_id => 'me.cliente_id'},
                {apelido    => 'cliente.apelido'},
                {avatar_url => 'cliente.avatar_url'},
                {activity   => \"TIMESTAMPDIFF( MINUTE, me.last_tm_activity, now() )"},
                {skills     => \q|JSON_ARRAYAGG(skill.skill)|},
                'me.last_tm_activity',
            ],
            order_by     => \'me.last_tm_activity DESC',
            group_by     => \'me.id',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            rows         => $rows + 1,
            offset       => $offset,
        }
    );

    if ($nome) {
        $rs = $rs->search(
            {
                '-or' => [
                    \['lower(cliente.nome_completo) like ?', "$nome%"],
                    \['lower(cliente.apelido) like ?',       "$nome%"],
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
        my $skills = $_->{skills} ? from_json($_->{skills}) : undef;
        $_->{skills} = join ', ', sort { $a cmp $b } grep {defined} $skills->@* if $skills;

        $_->{avatar_url} ||= $ENV{AVATAR_PADRAO_URL};

        # divide por 1440 pra transformar de minuto em dias
        $_->{activity}
          = $_->{activity} < 5
          ? 'online'
          : $activity_labels{int($_->{activity} / 1440)} || 'há muito tempo';

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

sub chat_profile_user {
    my ($c, %opts) = @_;

    my $user_obj   = $opts{user_obj}   or confess 'missing user_obj';
    my $cliente_id = $opts{cliente_id} or confess 'missing cliente_id';

    my $cliente = $c->schema2->resultset('Cliente')->search(
        {
            'me.id'                 => $cliente_id,
            'me.modo_anonimo_ativo' => '0',
            'me.status'             => 'active',

            'me.genero' => {in => ['MulherTrans', 'Feminino']},    # equivalente ao &is_female()
        },
        {
            join    => {'cliente_skills' => 'skill'},
            columns => [
                {cliente_id => 'me.id'},
                {apelido    => 'me.apelido'},
                {avatar_url => 'me.avatar_url'},
                {minibio    => 'me.minibio'},
                {skills     => \q|JSON_ARRAYAGG(skill.skill)|},
            ],
            group_by     => \'me.id',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->next;
    $c->reply_item_not_found() unless $cliente;

    my $skills = $cliente->{skills} ? from_json($cliente->{skills}) : undef;
    $cliente->{skills} = join ', ', sort { $a cmp $b } grep {defined} $skills->@* if $skills;
    $cliente->{avatar_url} ||= $ENV{AVATAR_PADRAO_URL};
    $cliente->{minibio}    ||= '';

    return {
        profile   => $cliente,
        is_myself => $cliente->{cliente_id} == $user_obj->id ? 1 : 0,
    };
}

1;
