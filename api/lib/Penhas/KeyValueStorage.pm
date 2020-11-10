package Penhas::KeyValueStorage;
use common::sense;
use MooseX::Singleton;
use Redis;
use Penhas::Logger qw(get_logger log_error);
use Carp qw/croak carp/;
use Digest::SHA qw(sha1_hex);
use Scope::OnExit;
use Sereal qw(sereal_encode_with_object
  sereal_decode_with_object);
my $sereal_enc = Sereal::Encoder->new();
my $sereal_dec = Sereal::Decoder->new();

has redis => (is => 'rw', isa => 'Redis', lazy => 1, builder => '_build_redis');

sub _build_redis {

    $ENV{REDIS_NS} ||= '';
    Redis->new(
        reconnect => 5,
        every     => 10_000,                                  # 10ms
        server    => $ENV{REDIS_SERVER} || '127.0.0.1:6379'
    );
}

has _functions_code => (is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_functions_code');

sub register_function {
    my ($self, $funcname) = @_;

    croak "function $funcname not found\n" unless exists $self->_functions_code->{$funcname};

    $self->redis->script_load($self->_functions_code->{$funcname}{code});
}

sub exec_function {
    my ($self, $funcname, @args) = @_;

    croak "function $funcname not found\n" unless exists $self->_functions_code->{$funcname};

    my @rets = eval { $self->redis->evalsha($self->_functions_code->{$funcname}{sha1}, @args) };
    if ($@ && $@ =~ /NOSCRIPT/) {
        $self->register_function($funcname);
        @rets = $self->redis->evalsha($self->_functions_code->{$funcname}{sha1}, @args);
    }
    elsif ($@) {
        die $@;
    }

    return wantarray ? @rets : \@rets;
}

sub _build_functions_code {
    my %funcs = (
        getAndInc => q~
local key     = KEYS[1]
local ttl = KEYS[2]

local curval = redis.call('get', key)

redis.call('incr', key)
if not curval then redis.call('expire', key, ttl) end

return curval
        ~,
        IncThenExpire => q~
local current
current = redis.call("incr", KEYS[1])
if tonumber(current) == 1 then
    redis.call("expire",KEYS[1],KEYS[2])
end

return current
        ~,
        lockSet => q~
local key     = KEYS[1]
local ttl     = KEYS[2]
local content = KEYS[3]

local lockSet = redis.call('setnx', key, content)

if lockSet == 1 then
redis.call('pexpire', key, ttl)
end

return lockSet
        ~,
    );

    $funcs{$_} = {code => $funcs{$_}, sha1 => sha1_hex($funcs{$_})} for keys %funcs;

    return \%funcs;
}

sub lock_and_wait {
    my ($self, $lock_key, $max_seconds) = @_;

    $lock_key = $ENV{REDIS_NS} . "lock:$lock_key";

    $max_seconds = defined $max_seconds && $max_seconds >= 1 ? $max_seconds : 15;

    my $interval  = 0.1;
    my $max_loops = $max_seconds * (1 / $interval);

    my $locked;
    while ($max_loops > 0) {

        ($locked) = $self->exec_function('lockSet', 3, $lock_key, $max_seconds * 1000, time());

        last if $locked;

        select undef, undef, undef, $interval;
        $max_loops--;
    }

    return wantarray ? ($locked, $lock_key) : $lock_key;
}

sub unlock {
    my ($self, $lock_key) = @_;
    $lock_key = $ENV{REDIS_NS} . "lock:$lock_key";

    $self->redis->del($lock_key);
}

sub redis_del {
    my ($self, $key) = @_;
    $self->redis->del($ENV{REDIS_NS} . $key);
}

sub local_get_count_and_inc {
    my ($self, %conf) = @_;

    my $ret = eval { ($self->exec_function('getAndInc', 2, 'rps:' . $conf{key}, $conf{expires}))[0] || 0 };
    if ($@) {
        log_error("Redis error: $@");
        return 0;
    }
    $ret;
}

sub redis_get_cached_or_execute {
    my ($self, $key, $ttl, $cb) = @_;

    my $iteration = 0;
    my $redis     = $self->redis;
    my $cache_key = $ENV{REDIS_NS} . $key;

  AGAIN:
    my $result = $redis->get($cache_key);
    if ($result) {
        return sereal_decode_with_object($sereal_dec, $result);
    }
    else {

        # faz um lock, potencialmente aguardando alguns segundos
        my (undef, $locked_key) = $self->lock_and_wait('cached_or_execute' . $cache_key);
        on_scope_exit { $self->redis->del($locked_key) };

        # busca novamente, caso outro worker tenha preenchido o valor
        $result = $redis->get($cache_key);
        return $result if defined $result;

        # se não tem resultado ainda, é realmente necessário calcular
        my $ret = $cb->();

        $redis->setex($cache_key, $ttl, sereal_encode_with_object($sereal_enc, $ret));

        return $ret;

    }
}

sub local_inc_then_expire {
    my ($self, %conf) = @_;

    my $ret = eval { ($self->exec_function('IncThenExpire', 2, $ENV{REDIS_NS} . $conf{key}, $conf{expires}))[0] || 0 };
    if ($@) {
        log_error("Redis error: $@");
        return -1;
    }
    $ret;
}

1;

