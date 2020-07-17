package Penhas::Helpers;
use Mojo::Base -base;
use Penhas::SchemaConnected;
use Penhas::Directus;
use Penhas::Controller;
use Penhas::Helpers::CPF;
use Penhas::Helpers::Quiz;
use Penhas::Helpers::ClienteSetSkill;
use Penhas::Helpers::Timeline;
use Penhas::Helpers::RSS;
use Penhas::Helpers::Guardioes;
use Penhas::KeyValueStorage;

use Carp qw/croak confess/;

sub setup {
    my $self = shift;

    Penhas::Helpers::Quiz::setup($self);
    Penhas::Helpers::Guardioes::setup($self);
    Penhas::Helpers::CPF::setup($self);
    Penhas::Helpers::Timeline::setup($self);
    Penhas::Helpers::ClienteSetSkill::setup($self);

    Penhas::Helpers::RSS::setup($self);

    state $kv = Penhas::KeyValueStorage->instance;
    $self->helper(kv             => sub {$kv});
    $self->helper(schema         => \&Penhas::SchemaConnected::get_schema);
    $self->helper(schema2        => \&Penhas::SchemaConnected::get_schema2);
    $self->helper(sum_cpf_errors => \&sum_cpf_errors);


    $self->helper(
        respond_to_if_web => sub {
            my $c = shift;

            my $accept = $c->req->headers->header('accept');
            if ($c->stash('template') && $accept && $accept =~ /html/) {
                $c->respond_to(@_);
            }
            else {
                my %opts = %{{@_}->{json}};
                die 'missing object json' unless $opts{json};
                $c->render(%opts);
            }
        }
    );

    $self->helper(
        assert_user_has_module => sub {
            my $c      = shift;
            my $module = shift or confess 'missing param $module';

            my $user_obj = $c->stash('user_obj') or confess 'missing stash.user_obj';

            $c->log->info(
                "Asserting user has access to module '$module' - user modules is: " . $user_obj->access_modules_str());

            die {status => 400, error => 'missing_module', message => "Você não tem acesso ao modulo $module",}
              unless $user_obj->has_module($module);

            return;
        }
    );
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

    $self->helper('reply_invalid_param' => sub { Penhas::Controller::reply_invalid_param(@_) });

    $self->helper(directus => sub { Penhas::Directus->instance });

}

sub sum_cpf_errors {
    my ($self, %opts) = @_;

    # contar quantas vezes o IP ja errou no ultimo dia
    my $total = $self->schema2->resultset('CpfErro')->search(
        {
            'reset_at'  => {'>' => DateTime->now->datetime(' ')},
            'remote_ip' => ($opts{remote_ip} or croak 'missing remote_ip'),
        }
    )->get_column('count')->sum()
      || 0;
    return $total;
}


1;
