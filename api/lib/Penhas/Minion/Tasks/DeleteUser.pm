package Penhas::Minion::Tasks::DeleteUser;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Digest::MD5 qw/md5_hex/;
use Penhas::Uploader;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(delete_user => \&delete_user);
}

sub delete_user {
    my ($job, $user_id) = @_;

    log_trace("minion:delete_user", $user_id);
    my $schema  = $job->app->schema;     # pg
    my $schema2 = $job->app->schema2;    # mysql

    my $logger = $job->app->log;

    my $user = $schema2->resultset('Cliente')->find($user_id);
    goto OK if !$user;

    my $email_md5 = md5_hex($user->email);
    $logger->info("deleting user email md5=$email_md5");

    my $emails_rs = $schema->resultset('EmaildbQueue')->search({to => $user->email});
    $logger->info('Email Queue WHERE "to" removed rows: ' . $emails_rs->delete());

    my $chat_sessions = $schema->resultset('ChatSession')->search(
        {
            session_started_by => $user->id,
        }
    );
    $logger->info('chat messages: ' . $chat_sessions->search_related('chat_messages')->delete());
    $logger->info('chat sessions: ' . $chat_sessions->delete());

    my $s3       = Penhas::Uploader->new();
    my $media_rs = $schema2->resultset('MediaUpload')->search({cliente_id => $user->id});
    my @ids;
    my $sum_deleted_bytes = 0;
    while (my $r = $media_rs->next) {

        $s3->remove_by_uri($r->s3_path);
        $s3->remove_by_uri($r->s3_path_avatar) if $r->s3_path_avatar;

        $sum_deleted_bytes += $r->file_size;
        $sum_deleted_bytes += $r->file_size_avatar if $r->file_size_avatar;
        push @ids, $r->id;
        $r->delete;
    }
    $logger->info("s3 deleted $sum_deleted_bytes bytes");

    $schema2->txn_do(
        sub {

            $schema2->resultset('DeleteLog')->create(
                {
                    data => to_json(
                        {
                            cpf_prefix             => $user->cpf_prefix,
                            cpf_hash               => $user->cpf_hash,
                            old_perform_delete_at  => $user->perform_delete_at,
                            deleted_scheduled_meta => (
                                $user->deleted_scheduled_meta
                                ? from_json($user->deleted_scheduled_meta)
                                : undef
                            ),
                            cep_double_hash     => md5_hex($user->cpf_hash . $user->cep),
                            dt_nasc_double_hash => md5_hex($user->cpf_hash . $user->dt_nasc),

                            media_upload_deleted => [@ids],
                            media_upload_bytes   => $sum_deleted_bytes,
                        }
                    ),
                    email_md5  => $email_md5,
                    created_at => \'now()',
                }
            );

            # todas FK estao DELETE CASCADE exceto a media_upload (que foi removida acima)
            $user->delete;
        }
    );

    if (is_test()) {
        $schema2->resultset('DeleteLog')->search({email_md5 => $email_md5})->delete;
    }

  OK:
    return $job->finish(1);

}

1;
