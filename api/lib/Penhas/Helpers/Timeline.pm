package Penhas::Helpers::Timeline;
use common::sense;
use Carp qw/croak/;
use utf8;
use Penhas::KeyValueStorage;

use JSON;
use Penhas::Logger;
use Penhas::Utils;

sub kv { Penhas::KeyValueStorage->instance }

sub setup {
    my $self = shift;

    $self->helper('add_tweet'    => sub { &add_tweet(@_) });
    $self->helper('delete_tweet' => sub { &delete_tweet(@_) });
}

sub delete_tweet {
    my ($c, %opts) = @_;

    my $user = $opts{user} or croak 'missing user';
    my $id   = $opts{id}   or croak 'missing id';

    slog_info(
        "del_tweet '%s'",
        $id,
    );

    my $item = $c->directus->search_one(
        table => 'tweets',
        form  => {
            form => {
                'filter[id][eq]'         => $id,
                'filter[cliente_id][eq]' => $user->{id},
            }
        }
    );
    die {
        message => 'Não foi possível encontrar a postagem.',
        error   => 'tweet_not_found'
    } if !$item;

    if ($item->{status} eq 'published') {
        $c->directus->update(
            table => 'tweets',
            id    => $item->{id},
            form  => {
                status => 'deleted',
            }
        );
    }

    return 1;
}

sub add_tweet {
    my ($c, %opts) = @_;

    my $user    = $opts{user}    or croak 'missing user';
    my $content = $opts{content} or croak 'missing content';
    my $reply_to = $opts{reply_to};

    # die {message => 'O conteúdo precisa ser menor que 500 caracteres', error => 'tweet_too_long'}
    #   if length $content > 500; Validado no controller

    if ($reply_to) {
        my $item = $c->directus->search_one(
            table => 'tweets',
            form  => {
                form => {
                    'filter[id][eq]'     => $reply_to,
                    'filter[status][eq]' => 'published',
                }
            }
        );
        die {
            message => 'Não foi possível comentar, postagem foi removida ou não existe mais.',
            error   => 'reply_to_not_found'
        } if !$item;
    }

    slog_info(
        "add_tweet '%s'",
        $content,
    );

    # captura o horario atual, e depois, fazemos um contador unico (controlado pelo redis),
    # o redis lembra por 60 segundos de "cada segundo tweetado", just in case
    # tenha algum retry lentidao na rede e varios tweets tentando processar.
  AGAIN:
    my $now     = DateTime->now;
    my $base    = substr($now->ymd(''), 2) . 'T' . $now->hms('');
    my $cur_seq = kv->local_inc_then_expire(
        key     => $base,
        expires => 60
    );

    # permite até 9999 tweets em 1 segundo, acho que ta ok pra este app!
    # se tiver tudo isso de tweet em um segundo, aguarda o proximo segundo!
    if ($cur_seq == 9999) {
        sleep 1;
        goto AGAIN;
    }
    my $id = $base . sprintf('%04d', $cur_seq);

    my $tweet = $c->directus->create(
        table => 'tweets',
        form  => {
            status       => 'published',
            id           => $id,
            content      => $content,
            'cliente_id' => $user->{id},
            anonimo      => $user->{modo_anonimo_ativo} ? 1 : 0,
            parent_id    => $reply_to,
            created_at   => $now->datetime(' '),
        }
    );
    die 'tweet_id missing' unless $tweet->{data}{id};
    return $tweet->{data};
}

1;
