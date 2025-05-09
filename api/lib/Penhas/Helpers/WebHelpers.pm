package Penhas::Helpers::WebHelpers;
use common::sense;
use Carp qw/confess croak/;
use utf8;
use JSON;
use Penhas::Logger;
use Penhas::Utils;
use JSON;

sub setup {
    my $c = shift;

    $c->helper(respond_to_if_web => \&respond_to_if_web);
    $c->helper(flash_to_redis    => \&flash_to_redis);
    $c->helper(use_redis_flash   => \&use_redis_flash);
    $c->helper(pg_timestamp2human => \&pg_timestamp2human);
    $c->helper(store_form_data   => \&store_form_data);
    $c->helper(get_form_data      => \&get_form_data);
    $c->helper(delete_form_data   => \&delete_form_data);
}

sub respond_to_if_web {
    my $c = shift;

    my $accept = $c->req->headers->header('accept');
    if (($c->stash('template') || $c->stash('use_flash_return')) && $accept && $accept =~ /html/) {
        my $ref_header = $c->req->headers->header('referer');
        if ($c->stash('use_flash_return')) {
            if (!$ref_header) {
                goto JSON;
            }
            else {
                my (%keys) = @_;
                my $html = $keys{html};
                if (defined $html && ref $html eq 'HASH') {
                    $c->log->debug("saving to flash " . to_json($html));

                    $html->{params} = $c->req->params->to_hash;

                    $c->flash_to_redis($html);

                    return $c->redirect_to($ref_header);
                }
            }
        }

        $c->respond_to(@_);
    }
    else {
      JSON:
        my %opts = %{{@_}->{json}};
        die 'missing object json' unless $opts{json};
        $c->render(%opts);
    }
}

sub use_redis_flash {
    my $c = shift;

    $c->stash(pg_timestamp2human => \&pg_timestamp2human);

    my $flashredis = $c->flash('flashredis');
    if ($flashredis) {
        my $loaded = $c->kv->redis->get($flashredis);
        $c->kv->redis->del($flashredis);
        if ($loaded) {
            $loaded = from_json($loaded);
            $c->stash(%$loaded);
        }
    }

    $c->stash(use_flash_return => 1) if $c->req->method eq 'POST';
}

sub flash_to_redis {
    my $c         = shift;
    my $content   = shift;
    my $redis_key = 'flash' . random_string(10);
    $c->kv->redis->setex($redis_key, 15, to_json($content));
    $c->flash(flashredis => $redis_key);
}


sub store_form_data {
    my ($c, $data) = @_;

    # Generate a unique key for this form submission
    my $form_key = 'form_data_' . Penhas::Utils::random_string(16);

    # Store the data in Redis with a longer TTL (24 hours = 86400 seconds)
    $c->kv->redis->setex($form_key, 86400, to_json($data));

    return $form_key;
}

sub get_form_data {
    my ($c, $key) = @_;

    # Get the data from Redis (don't delete it yet)
    my $data = $c->kv->redis->get($key);

    return $data ? from_json($data) : undef;
}

sub delete_form_data {
    my ($c, $key) = @_;

    # Delete the data from Redis when no longer needed
    $c->kv->redis->del($key);
}

1;
