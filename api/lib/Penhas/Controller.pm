package Penhas::Controller;
use Mojo::Base 'Mojolicious::Controller';
use utf8;

use Scalar::Util qw(blessed);

use Penhas::KeyValueStorage;
my $kv = Penhas::KeyValueStorage->instance;

my $campos_nao_foram_preenchidos = 'Campos não foram preenchidos corretamente';

sub apply_request_per_second_limit {
    my $c       = shift;
    my $limit   = shift || 3;
    my $expires = shift || 1;

    my $key = $c->stash('apply_rps_on');
    return 1 unless $key;
    return 1 if $ENV{DISABLE_RPS_LIMITER};

    $limit *= 10 if $ENV{IS_DEV};

    my $reqcount = $kv->local_get_count_and_inc(key => $key, expires => $expires);
    if ($reqcount > $limit) {
        die {
            error   => 'too_many_requests',
            message => 'Você fez muitos acessos recentemente. Aguarde um minuto e tente novamente.'
              . ($ENV{IS_DEV} ? ('DEV ONLY: ' . $reqcount . '/' . $limit) : ''),
            status => 429,
        };
    }
    return 1;
}

sub reply_not_found {
    my $c = shift;

    die {error => 'Page not found', message => 'Página ou item não existe', status => 404,};
}

sub reply_invalid_param {
    my ($c, $message, $error, $field, $reason) = @_;

    die {
        message => "$message",
        error   => $error || 'form_error',
        (defined $field ? (field => $field, reason => $reason || 'invalid') : ()),
        status => 400,
    };
}

sub reply_item_not_found {
    my $c = shift;

    die {
        error   => 'item_not_found',
        message => 'O objeto requisitado não existe ou você não tem permissão para acessa-lo.', status => 404,
    };
}

sub reply_forbidden {
    my $c = shift;

    if ($c->stash('layout')) {
        $c->redirect_to('/admin/login');
        return 0;
    }
    else {
        die {
            error   => 'permission_denied',
            message => 'Você não tem a permissão para este recurso.',
            status  => 403,
        };
    }
}

sub method_not_allowed {
    my $c = shift;

    return $c->reply_method_not_allowed();
}

sub reply_method_not_allowed {
    my $c = shift;

    die {error => 'method_not_allowed', message => 'Method not allowed', status => 405,};
}

sub reply_exception {
    my $c   = shift;
    my $err = shift;
    my $ret = eval { &_reply_exception($c, $err) };
    if ($@) {
        my $err = $@;
        $c->app->log->fatal($c->dumper($err));
        $c->app->log->fatal("reply_exception generated an exception!!!");
        $c->render(text => 'reply_exception generated an exception', status => 500);
        return 1;
    }
    return $ret if $ret;
}

sub _reply_exception {
    my $c        = shift;
    my $an_error = shift;

    if ($an_error) {

        if (ref $an_error eq 'HASH' && exists $an_error->{error}) {
            my $status = delete $an_error->{status} || 400;
            $c->app->log->info('error 400: ' . $c->app->dumper($an_error));

            $an_error->{message} = $campos_nao_foram_preenchidos unless exists $an_error->{message};
            return $c->respond_to_if_web(
                json => {json => $an_error, status => $status,},
                html => {
                    template => $c->stash('template') || 'guardiao/index',
                    %$an_error,
                    status => 200
                }
            );
        }
        elsif (ref $an_error eq 'REF' && ref $$an_error eq 'ARRAY' && @$$an_error == 2) {

            $c->app->log->info('error 400: ' . $c->app->dumper($an_error));
            return $c->respond_to_if_web(
                json => {
                    json => {
                        error   => 'form_error',
                        field   => $$an_error->[0],
                        reason  => $$an_error->[1],
                        message => $campos_nao_foram_preenchidos
                    },
                    status => 400,
                },
                html => {
                    error   => 'form_error',
                    field   => $$an_error->[0],
                    reason  => $$an_error->[1],
                    message => $campos_nao_foram_preenchidos,
                }
            );
        }
        elsif (ref $an_error eq 'DBIx::Class::Exception'
            && $an_error->{msg} =~ /duplicate key value violates unique constraint/)
        {
            $c->app->log->info('Exception treated: ' . $an_error->{msg});

            return $c->render(
                json => {
                    error   => 'duplicate_key_violation',
                    message => 'You violated an unique constraint! Please verify your input fields and try again.'
                },
                status => 400,
            );
        }
        elsif (ref $an_error eq 'DBIx::Class::Exception' && $an_error->{msg} =~ /is not present/) {
            my ($match, $value) = $an_error->{msg} =~ /Key \((.+?)\)=(\(.+?)\)/;

            return $c->render(
                json => {
                    error   => 'fk_violation',
                    message => sprintf 'key=%s value=%s cannot be found on our database',
                    $match, $value
                },
                status => 400,
            );
        }
        elsif (ref $an_error eq 'HASH' && $an_error->{error_code}) {
            $c->app->log->info('Exception treated: ' . $an_error->{message});

            return $c->render(
                json   => {error => 'generic_exception', message => $an_error->{message}},
                status => $an_error->{error_code} || 500,
            );
        }

        $c->app->log->fatal(blessed($an_error)
              && UNIVERSAL::can($an_error, 'message') ? $an_error->message : $c->app->dumper($an_error));
    }

    return $c->render(json => {error => "Internal server error", message => 'Erro interno'}, status => 500,);
}


sub merge_validate_request_params {
    my ($c, $merge, %fields) = @_;
    my $extend = $c->validate_request_params(%fields);
    $merge->{$_} = $extend->{$_} for keys %$extend;
    return 1;
}

sub validate_request_params {
    my ($c, %fields) = @_;

    my $params = $c->req->params->to_hash;
    my $tested = {};
    foreach my $key (keys %fields) {
        my $me   = $fields{$key};
        my $type = $me->{type};
        next if !exists $params->{$key} && !$me->{required};

        my $val = $params->{$key};
        if (!defined $val && $me->{undef_if_missing}) {
            $tested->{$key} = undef;
            next;
        }

        my %def_message = (message => $campos_nao_foram_preenchidos . ' (' . $key . ')');
        if (defined($val) && (exists $me->{min_length} || exists $me->{max_length})) {
            my $len     = length $val;
            my $min_len = $me->{min_length};
            my $max_len = $me->{max_length};

            if (defined($max_len) && $len > $max_len) {
                my %msg = %def_message;
                $c->log->debug($val);
                $msg{message} .= ' máximo: ' . $max_len . ' enviado: ' . $len;
                die {error => 'form_error', field => $key, reason => 'invalid_max_length', %msg, status => 400};
            }

            if (defined($min_len) && $len < $min_len) {
                my %msg = %def_message;
                $c->log->debug($val);
                $msg{message} .= ' mínimo: ' . $min_len . ' enviado: ' . $len;
                die {error => 'form_error', field => $key, reason => 'invalid_min_length', %msg, status => 400};
            }
        }

        if (!defined $val && $me->{required} && !($me->{undef_is_valid} && !defined $val)) {
            die {error => 'form_error', field => $key, reason => 'is_required', x => 1, %def_message, status => 400};
        }

        if (
               defined $val
            && $val eq ''
            && (exists $me->{empty_is_valid} ? !$me->{empty_is_valid} : 1)
            && (  !$me->{empty_is_valid}
                || $me->{empty_is_invalid}
                || $type eq 'Bool'
                || $type eq 'Int'
                || $type eq 'Num'
                || ref $type eq 'MooseX::Types::TypeDecorator')
          )
        {
            die {error => 'form_error', field => $key, reason => 'is_required', x => 2, %def_message, status => 400};
        }

        $tested->{$key} = $val;
        next unless $val;

        my $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint($type);

        if (!defined $cons) {
            die {message => "Unknown type constraint '$type'", status => 500,};
        }

        if (!$cons->check($val)) {
            die {error => 'form_error', field => $key, reason => 'invalid', %def_message, _val => $val, status => 400};
        }
    }

    return $tested;
}


1;
