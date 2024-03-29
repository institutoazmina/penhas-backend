package Penhas::Minion::Tasks::SendSMS;
use Mojo::Base 'Mojolicious::Plugin';
use Penhas::Utils qw/is_test/;
use JSON;
use utf8;
use Penhas::Logger;
use Amazon::SNS;

sub register {
    my ($self, $app) = @_;

    $app->minion->add_task(send_sms => \&send_sms);
}

sub send_sms {
    my ($job, $phonenumber, $message) = @_;

    log_trace("minion:send_sms", $phonenumber);
    my $schema = $job->app->schema2;

    my $notes = is_test() ? $job->{notes} : $job->info()->{notes};

    my $log = $schema->resultset('SentSmsLog')->create(
        {
            phonenumber => $phonenumber,
            message     => $message,
            notes       => to_json($notes),
            created_at  => \'NOW()',
        }
    );
    log_trace("SentSmsLog", $log->id);

    return $job->finish('is_test') if is_test();

    die 'missing AWS_SNS_KEY'    unless $ENV{AWS_SNS_KEY};
    die 'missing AWS_SNS_SECRET' unless $ENV{AWS_SNS_SECRET};

    my $sns = Amazon::SNS->new(
        {
            'key'    => $ENV{AWS_SNS_KEY},
            'secret' => $ENV{AWS_SNS_SECRET},
        }
    );
    $sns->service($ENV{AWS_SNS_ENDPOINT} || 'http://sns.sa-east-1.amazonaws.com');

    my $r = $sns->dispatch(
        {
            'Action'      => 'Publish',
            'Message'     => $message,
            'PhoneNumber' => $phonenumber,
            'Attributes'  => {
                'MessageAttributes.entry.1.Name'              => 'AWS.SNS.SMS.SMSType',
                'MessageAttributes.entry.1.Value.StringValue' => 'Transactional',
                'MessageAttributes.entry.1.Value.DataType'    => 'String',
            }
        }
    );

    my $success = $r->{'PublishResult'}{'MessageId'};
    if (!$success) {
        $log->update({sns_message_id => 'failed: ' . $sns->error()});
        return $job->fail($r->error());
    }
    $log->update({sns_message_id => $success});

    return $job->finish($success);
}

1;
