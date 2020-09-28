package Penhas::Controller::Me_Media;
use Mojo::Base 'Penhas::Controller';
use utf8;
use JSON;
use Imager;
use DateTime;
use Digest::SHA1;
use Scope::OnExit;
use Penhas::Types qw/UploadIntention/;
use Penhas::Uploader;
use Penhas::Utils qw/get_media_filepath random_string/;
use Penhas::Logger;
use IPC::Run3;
use File::Temp;
use Fcntl qw(SEEK_SET);
use MIME::Base64;
use Mojo::File;

has _uploader => sub { Penhas::Uploader->new() };

sub assert_user_perms {
    my $c = shift;

    die 'missing user' unless $c->stash('user');

    die {
        error   => 'upload_blocked',
        message => 'Upload está bloqueado para sua conta',
    } if $c->stash('user')->{upload_status} eq 'blocked_all';

    return 1;
}

sub upload {
    my $c      = shift;
    my $params = $c->req->params->to_hash;

    my $is_audio_upload = $c->stash('is_audio_upload');
    if ($is_audio_upload) {
        $params->{intention} = 'guardiao';
    }
    else {
        $c->validate_request_params(
            intention => {max_length => 200, required => 1, type => UploadIntention},
        );
    }

    die {
        error   => 'upload_blocked',
        message => 'Upload está bloqueado para sua conta',
    } if $c->stash('user')->{upload_status} eq 'only_guardiao' && $params->{intention} ne 'guardiao';

    my $upload = $c->param('media');
    $c->log->info(sprintf 'file size is %s', $upload->size);
    if (!$upload) {
        die {
            error   => 'media_missing',
            message => 'Upload não foi enviado',
        };
    }
    elsif ($upload->size <= 2) {
        die {
            error   => 'media_invalid_size',
            message => 'Upload precisa ter mais do que 2 bytes',
        };
    }
    elsif (!$is_audio_upload && $upload->size > 5_000_000) {
        die {
            error   => 'media_too_big',
            message => 'Arquivo muito grande, precisa ser menor que 5 Megabytes',
        };
    }
    elsif ($is_audio_upload && $upload->size > 15_000_000) {
        die {
            error   => 'media_too_big',
            message => 'Arquivo muito grande, precisa ser menor que 15 Megabytes',
        };
    }

    my $upload_asset = $upload->asset->to_file;
    my $sha1         = Digest::SHA1->new;
    $upload_asset->handle->sysseek(0, SEEK_SET);
    $sha1->addfile($upload_asset->handle);
    my $file_sha1 = $sha1->hexdigest;

    my $cliente_id = $c->stash('user')->{id};
    my $rs         = $c->schema2->resultset('MediaUpload');

    # upload duplicado [por mesmo usuário], retorna o mesmo ID
    my ($ret, $existing) = $rs->search({cliente_id => $cliente_id, file_sha1 => $file_sha1})->next;
    if ($existing) {
        $ret = $existing;
        goto RENDER;
    }

    # Quando o upload é pequeno, o Mojo otimiza deixando tudo na RAM. Para fazer o upload pra S3, é necessário
    # mover para um arquivo em disco.
    my $ext = (split(m{\.}, $upload->filename))[-1];

    # Em caso de PNG, vamos mudar pra JPEG (pelo menos ate alguem reclamar de transparencia kk)
    my $convert_ext = $ext =~ /png/i ? 'jpg' : $ext;

    my $dbh_pg    = $c->schema->storage->dbh;
    my $now       = DateTime->now;
    my $id        = $dbh_pg->selectrow_arrayref("select uuid_generate_v4()", {Slice => {}})->[0];
    my $s3_prefix = sprintf(
        '%s/cliente_%d/%sT%s.%s',
        $params->{intention},
        $cliente_id,
        $now->date('-'),
        $now->hms(''),
        $id
    );

    my $media = get_media_filepath("$id.tmp-orig.$ext");
    $upload->move_to($media);
    on_scope_exit {
        unlink($media);
    };

    my $row;
    if ($ext =~ /(png|jpeg|jpg)/i) {
        my $media_sd = "$media.sd.$convert_ext";
        my $media_hd = "$media.hd.$convert_ext";
        on_scope_exit {
            unlink $media_hd;
            unlink $media_sd;
        };

        my $image = Imager->new;
        $image->set_file_limits(width => 5_000, height => 5_000, bytes => (5_000 * 5_000 * 4) * 1.2,);

        $image->read(file => $media);
        die {error => 'imager_error', message => "Erro ao processar imagem: " . $image->errstr}
          if $image->errstr;

        my $max_xpixels_sd = $ENV{MAX_UPLOAD_SD_X_PIXELS} || 360;
        my $max_ypixels_sd = $ENV{MAX_UPLOAD_SD_Y_PIXELS} || 240;

        my $max_xpixels_hd = $ENV{MAX_UPLOAD_HD_X_PIXELS} || 1620;
        my $max_ypixels_hd = $ENV{MAX_UPLOAD_HD_Y_PIXELS} || 1080;

        my $image_sd = $image;

        # se altura ou largura passar, faz o resize
        if ($image->getwidth > $max_xpixels_sd || $image->getheight > $max_ypixels_sd) {
            $image_sd
              = $image->scale(xpixels => $max_xpixels_sd, ypixels => $max_ypixels_sd, qtype => 'mixing', type => 'min');
        }
        $image_sd->write(file => $media_sd) or die $image_sd->errstr;

        if ($image->getwidth > $max_xpixels_hd || $image->getheight > $max_ypixels_hd) {
            $image
              = $image->scale(xpixels => $max_xpixels_hd, ypixels => $max_ypixels_hd, qtype => 'mixing', type => 'min');
        }
        $image->write(file => $media_hd) or die $image->errstr;

        my $sd
          = $c->_uploader->upload({path => $s3_prefix . ".sd.$convert_ext", file => $media_sd, type => 'image/jpeg',});

        my ($hd, $uploaded) = ($sd, 0);

        # se a resolucao eh diferente, faz upload, caso contrario copia
        if (join('', $image_sd->getwidth, $image_sd->getheight) ne join('', $image->getwidth, $image->getheight)) {
            $uploaded++;
            $hd = $c->_uploader->upload(
                {path => $s3_prefix . ".hd.$convert_ext", file => $media_hd, type => 'image/jpeg',});
        }

        $row = {
            file_info => to_json(
                {
                    sd_dim => [$image_sd->getwidth, $image_sd->getheight],
                    hd_dim => [$image->getwidth,    $image->getheight],
                    o_ext  => $ext,
                }
            ),
            file_size        => $uploaded ? -s $media_hd : 0,
            file_size_avatar => -s $media_sd,
            s3_path          => $hd,
            s3_path_avatar   => $sd,
        };

    }
    elsif ($ext =~ /(aac|m4a|mp4)/) {

        log_info("converting audio upload...");

        # Convertendo o arquivo para AAC para funcionar no Android e no iPhone.
        # e normaliza em 96 kbps aac_he_v2 [standardized 2006]
        my $fhout = File::Temp->new(UNLINK => 1, SUFFIX => ".aac", OPEN => 0);

        my @ffmpeg = ();
        push @ffmpeg, qw(ffmpeg -i);
        push @ffmpeg, $media;
        push @ffmpeg, qw(-acodec aac -strict -2 -ab 96k -y -loglevel debug -movflags +faststart -f mp4);
        push @ffmpeg, $fhout->filename;

        my $stderr = '';
        my $stdout = '';

        eval { run3 \@ffmpeg, \undef, \$stdout, \$stderr; };

        if ($@ || -z $fhout->filename) {
            log_error("converting audio upload FAILED: $@ - $stderr $stdout");
            undef $fhout;

            if (-d $ENV{MEDIA_ERR_DIR}) {
                my $keep_original
                  = $ENV{MEDIA_ERR_DIR} . '/'
                  . join('.', 'cliente_id_' . $cliente_id, $now->ymd('-'), random_string(10)) . ".$ext";

                $upload->move_to($keep_original);
                log_error("original file kept at $keep_original");
            }

            die {
                error   => 'unsupported_media_type',
                message => 'O arquivo de áudio está corrompido ou não é suportado.',
            };
        }

        if ($c->stash('extract_waveform')) {
            $c->stash('waveform' => &_extract_waveform($fhout->filename));
        }
        $c->stash('audio_duration' => &_extract_duration($fhout->filename));

        my $s3 = $c->_uploader->upload({path => $s3_prefix . ".aac", file => $fhout->filename, type => 'audio/aac',});

        $row = {
            file_info => to_json(
                {
                    o_ext  => $ext,
                    o_size => $upload->size,
                }
            ),
            file_size => -s $fhout->filename,
            s3_path   => $s3,
        };

        undef $fhout;
    }
    else {
        die {
            error   => 'unsupported_media_type',
            message => 'Tipo de arquivo não é suportado.',
        };
    }

    $row->{id}         = $id;
    $row->{intention}  = $params->{intention};
    $row->{file_sha1}  = $file_sha1;
    $row->{cliente_id} = $cliente_id;
    $row->{created_at} = DateTime->now->datetime(' ');

    $ret = $rs->create($row);

    return $ret if $c->stash('return_upload');
  RENDER:

    return $c->render(
        json => {
            id => $ret->id,
        },
        status => 200,
    );
}

sub _extract_waveform {
    my ($media) = @_;

    my $tmp    = File::Temp->new(UNLINK => 1, SUFFIX => ".png", OPEN => 0);
    my @ffmpeg = ();
    push @ffmpeg, qw(ffmpeg -i);
    push @ffmpeg, $media;
    push @ffmpeg, '-filter_complex', 'compand,showwavespic=s=420x80';# :colors=#9f63ff
    push @ffmpeg, qw(-c:v png -f image2 -frames:v 1 -y  -loglevel debug);
    push @ffmpeg, $tmp->filename;

    my $stderr = '';
    my $stdout = '';
    eval { run3 \@ffmpeg, \undef, \$stdout, \$stderr; };

    if ($@ || -z $tmp->filename) {
        log_error("extrating waveform FAILED: $@ - $stderr $stdout");
        undef $tmp;
        die {
            error   => 'extract_waveform_error',
            message => 'Erro ao ler arquivo convertido',
        };
    }

    my $content = encode_base64(Mojo::File->new($tmp->filename)->slurp, '');
    undef $tmp;

    return $content;
}

sub _extract_duration {
    my ($media) = @_;

    my @ffprobe = ();
    push @ffprobe, qw(ffprobe -i);
    push @ffprobe, $media;
    push @ffprobe, qw(-show_entries format=duration);
    push @ffprobe, qw(-v quiet);
    push @ffprobe, '-of', 'csv=p=0';

    my $stderr = '';
    my $stdout = '';
    eval { run3 \@ffprobe, \undef, \$stdout, \$stderr; };

    chomp($stdout);
    if ($@ || $stdout !~ /^\d{1,5}\.\d{1,}$/a) {
        log_error("extrating duration FAILED: $@ - $stderr $stdout");
        die {
            error   => 'extract_duration_error',
            message => 'Erro ao ler arquivo convertido',
        };
    }

    return $stdout;
}


1;
