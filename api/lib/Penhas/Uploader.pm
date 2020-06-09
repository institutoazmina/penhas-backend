package Penhas::Uploader;
use common::sense;
use MooseX::Singleton;

use URI;
use URI::Escape;
use Net::Amazon::S3;
use Digest::HMAC_SHA1;
use MIME::Base64 qw(encode_base64);

use Penhas::Utils;

has access_key => (is => 'rw', isa => 'Str', lazy => 1, default => $ENV{PENHAS_S3_ACCESS_KEY},);

has secret_key => (is => "rw", isa => 'Str', lazy => 1, default => $ENV{PENHAS_S3_SECRET_KEY},);

has media_bucket => (is => "rw", isa => 'Str', lazy => 1, default => $ENV{PENHAS_S3_MEDIA_BUCKET},);

has _s3 => (is => "ro", isa => "Net::Amazon::S3", lazy_build => 1, handles => [qw/ err errstr /],);

sub _build__s3 {
    my ($self) = @_;

    defined $self->access_key   or die "missing 'access_key'.";
    defined $self->secret_key   or die "missing 'secret_key'.";
    defined $self->media_bucket or die "missing 'media_bucket'.";

    return Net::Amazon::S3->new(
        {
            aws_access_key_id     => $self->access_key,
            aws_secret_access_key => $self->secret_key,
            host                  => $ENV{PENHAS_S3_HOST} || 's3.amazonaws.com',
            retry                 => 1,
            timeout               => 3,
            secure                => 1,
        }
    );
}

sub upload {
    my ($self, $args) = @_;

    # Required args.
    defined $args->{$_} or die "missing '$_'" for qw(file path type);

    if (is_test()) {
        return URI->new("https://fake.url/" . $args->{path});
    }

    my $bucket = $self->_s3->bucket($self->media_bucket);

    $bucket->add_key_filename($args->{path}, $args->{file}, {content_type => $args->{type}});

    if ($self->err) {
        die $self->err . ': ' . $self->errstr;
    }

    my $sign_url = $self->_generate_auth_uri($args->{path}, 2145916800);

    return URI->new($sign_url);
}

sub _generate_auth_uri {
    my ($self, $path, $expires) = @_;

    my $bucket = $self->media_bucket;
    $expires ||= 2145916800;    # Jan 1, 2038

    my $str = "GET\n\n\n$expires\n/$bucket/$path";

    my $access = uri_escape($self->access_key);
    my $sig    = uri_escape($self->_encode($str));

    return "https://$bucket.s3.amazonaws.com/$path?AWSAccessKeyId=$access&Expires=$expires&Signature=$sig";
}

sub _encode {
    my ($self, $str) = @_;

    my $hmac = Digest::HMAC_SHA1->new($self->secret_key);
    $hmac->add($str);

    return encode_base64($hmac->digest, '');
}

__PACKAGE__->meta->make_immutable;

1;
