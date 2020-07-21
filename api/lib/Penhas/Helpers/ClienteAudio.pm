package Penhas::Helpers::ClienteAudio;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Number::Phone::Lib;
use Penhas::Utils qw/random_string_from is_test/;
use Digest::MD5 qw/md5_hex/;

sub setup {
    my $self = shift;

    $self->helper('cliente_new_audio'  => sub { &cliente_new_audio(@_) });
    $self->helper('cliente_list_audio' => sub { &cliente_list_audio(@_) });
}

sub cliente_new_audio {
    my ($c, %opts) = @_;

    my $user_obj           = $opts{user_obj}           or confess 'missing user_obj';
    my $cliente_created_at = $opts{cliente_created_at} or confess 'missing cliente_created_at';
    my $media_upload       = $opts{media_upload}       or confess 'missing media_upload';

    my $row = $user_obj->clientes_audios->create(
        {
            media_upload_id    => $media_upload->id,
            cliente_created_at => $cliente_created_at,
            status             => 'free_access',
            created_at         => \'NOW()',
        }
    );

    my $message = 'Áudio recebido com sucesso!';
    return {
        message => $message,
        data    => &_format_audio_row($c, $user_obj, $row),
    };
}

sub _format_audio_row {
    my ($c, $user_obj, $row) = @_;

    return {
        id                 => $row->id,
        cliente_created_at => $row->cliente_created_at->datetime,
    };
}


1;
