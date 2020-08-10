package Penhas::Helpers::Geolocation;
use common::sense;
use Carp qw/confess/;
use utf8;
use JSON;
use Penhas::Logger;
use Penhas::Utils qw/is_test/;
use Mojo::Util qw/url_escape/;

sub setup {
    my $self = shift;

    $self->helper('reverse_geo_code' => sub { &reverse_geo_code(@_) });
    $self->helper('geo_code'         => sub { &geo_code(@_) });
}

sub geo_code {
    my ($c, $address) = @_;

    my $data;
    eval {
        if ($ENV{GEOCODE_USE_HERE_API}) {
            my $uri
              = 'https://geocoder.api.here.com/search/6.2/geocode.json?languages=pt-BR&maxresults=1'
              . '&searchtext='
              . url_escape($address);
            log_info("executing GET $uri");
            use DDP;
            p $uri;
            $uri .= '&app_id=' . $ENV{GEOCODE_HERE_APP_ID}
              if exists $ENV{GEOCODE_HERE_APP_ID} && defined $ENV{GEOCODE_HERE_APP_ID};
            $uri .= '&app_code=' . $ENV{GEOCODE_HERE_APP_CODE}
              if exists $ENV{GEOCODE_HERE_APP_CODE} && defined $ENV{GEOCODE_HERE_APP_CODE};

            my $result = $c->ua->get($uri)->result;
            my $json   = $result->json;

            log_info($c->app->dumper($json)) if $json;
            if (exists $json->{Response}{View}[0]{Result}[0]{Location}{DisplayPosition}{Latitude}) {

                $data = $json->{Response}{View}[0]{Result}[0]{Location}{DisplayPosition}{Latitude} . ','
                  . $json->{Response}{View}[0]{Result}[0]{Location}{DisplayPosition}{Longitude};
            }
            else {
                log_error($c->app->dumper($result)) if $result;
                die "Error.zero_results\n";
            }

        }
        else {

            my $uri
              = 'https://maps.googleapis.com/maps/api/geocode/json'
              . '?address='
              . url_escape($address)
              . '&language=pt-br';
            log_info("executing GET $uri");
            $uri .= '&key=' . $ENV{GOOGLE_GEOCODE_API}
              if exists $ENV{GOOGLE_GEOCODE_API} && defined $ENV{GOOGLE_GEOCODE_API};

            my $result = $c->ua->get($uri)->result;
            my $json   = $result->json;
            log_info($c->app->dumper($json)) if $json;

            if (exists $json->{results}[0]{geometry}{location}{lat}) {
                $data
                  = $json->{results}[0]{geometry}{location}{lat} . ',' . $json->{results}[0]{geometry}{location}{lng};
            }
            else {
                log_error($c->app->dumper($result)) if $result;
                die "Error.zero_results\n";
            }

        }
    };
    if ($@) {
        log_error($c->app->dumper($@)) if "$@" !~ /Error.zero_results/;
        return undef;
    }

    return $data;
}

sub reverse_geo_code {
    my ($c, $lat_lng) = @_;

    my $data;

    eval {
        if ($ENV{GEOCODE_USE_HERE_API}) {
            my $uri
              = 'https://reverse.geocoder.api.here.com/6.2/reversegeocode.json'
              . '?prox='
              . $lat_lng
              . ',0&mode=retrieveAddresses&maxresults=1&gen=9';
            $uri .= '&app_id=' . $ENV{GEOCODE_HERE_APP_ID}
              if exists $ENV{GEOCODE_HERE_APP_ID} && defined $ENV{GEOCODE_HERE_APP_ID};
            $uri .= '&app_code=' . $ENV{GEOCODE_HERE_APP_CODE}
              if exists $ENV{GEOCODE_HERE_APP_CODE} && defined $ENV{GEOCODE_HERE_APP_CODE};
            log_info("executing GET $uri");

            my $result = $c->ua->get($uri)->result;
            my $json   = $result->json;

            if (exists $json->{Response}{View}[0]{Result}[0]{Location}{Address}{Label}) {
                $data = $json->{Response}{View}[0]{Result}[0]{Location}{Address}{Label};
            }
            else {
                log_error($c->app->dumper($result)) if $result;
                die "Error.zero_results\n";
            }

        }
        else {

            my $uri = 'https://maps.googleapis.com/maps/api/geocode/json' . '?latlng=' . $lat_lng . '&language=pt-br';
            $uri .= '&key=' . $ENV{GOOGLE_GEOCODE_API}
              if exists $ENV{GOOGLE_GEOCODE_API} && defined $ENV{GOOGLE_GEOCODE_API};

            log_info("executing GET $uri");

            my $result = $c->ua->get($uri)->result;
            my $json   = $result->json;

            if (exists $json->{results}[0]{formatted_address}) {
                $data = $json->{results}[0]{formatted_address};
            }
            else {
                log_error($c->app->dumper($result)) if $result;
                die "Error.zero_results\n";
            }

        }
    };
    if ($@) {
        log_error($c->app->dumper($@)) if "$@" !~ /Error.zero_results/;
        return undef;
    }

    return $data;
}

1;
