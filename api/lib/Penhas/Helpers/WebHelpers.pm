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

1;
