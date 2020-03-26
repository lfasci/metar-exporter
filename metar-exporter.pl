#!/usr/bin/perl
 
package geoMetarPrometheusExporter;
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use Config::YAML;
use WWW::Mechanize;
use Geo::METAR;
use CGI;
use Time::Local;
use Data::Dumper;
use Text::Unidecode;
use strict;
use Fcntl ':flock';

open my $self, '<', $0 or die "Couldn't open self: $!";
flock $self, LOCK_EX | LOCK_NB or die "This script is already running";

my $configFile = $ARGV[0] || "/etc/sensors/metar.yml";
my $config = Config::YAML->new( config => $configFile);
my $baseUrl = $config->{base_url};
my $httpPort = $config->{http_port};

#Metar
my $baseUrl = $config->{metar_base_url};
my $httpPort = $config->{metar_http_port};
my $metarlocations = $config->{metar_locations};

my $pid = geoMetarPrometheusExporter->new($httpPort)->background();

#################################################################################################

sub getSensors() {
	my $metarlocations = shift;
	my $printTimestamp = shift;

	my $output = "#Metar data\n";
	foreach my $var (@$metarlocations)  {
		foreach my $location (keys(%$var)) {
			my $province = $var->{$location}->{province};
			my $code = $var->{$location}->{stationcode};
			my $geohash = $var->{$location}->{geohash};
			my $agent = WWW::Mechanize->new();
			my $req = $baseUrl.$code.".TXT";
			$agent->get($req );
			my $metar =  $agent->content();
			my @rows= split("\n",$metar);
			my $m = new Geo::METAR;
			$m->metar($rows[1]);

			#METAR info are update few times a day 
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
			$year = $year+1900;
			$hour = substr($m->date_time,2,2);
			$min = substr($m->date_time,4,2);
			my $timestamp = timelocal($sec,$min,$hour,$mday,$mon,$year);
			
			$location = &cleanString($location);
			#Wind
			$output .= "# ".$location." ".$code."\n";
			my $wmph = $m->WIND_MPH;
			my $windDirection = $m->WIND_DIR_ABB;
			my $measureVal = int($wmph * 1.60934);
			if ($printTimestamp) {
				$output .= "wind_speed{province=\"$province\",location=\"$location\",winddirection=\"$windDirection\",geohash=\"$geohash\"} $measureVal $timestamp\n";
			} else {
				$output .= "wind_speed{province=\"$province\",location=\"$location\",winddirection=\"$windDirection\",geohash=\"$geohash\"} $measureVal\n";
			}	

			#Temperature
			$measureVal = $m->TEMP_C;
			if ($printTimestamp) {
				$output .= "temperature{province=\"$province\",province=\"$province\",location=\"$location\",geohash=\"$geohash\"} $measureVal $timestamp\n";
			} else {
				$output .= "temperature{province=\"$province\",province=\"$province\",location=\"$location\",geohash=\"$geohash\"} $measureVal\n";
			}
		}
	}
	my $cgi = CGI->new();
	my $nl = "\x0d\x0a";
	print "HTTP/1.0 200 OK$nl";
	print $cgi->header("text/plain"),$output;
}

#Prometheus only accepts ASCII so I have to clean strings
sub cleanString {
	my $str = shift;
	$str = unidecode($str);
	$str =~ s/[^a-zA-Z0-9,\s]/ /g;
	$str =~ s/\s+/ /g;
	if(substr ($str, -1) eq ' '){
		chop $str;
	}
	return $str;
}

sub handle_request {
	my $self = shift;
	my $cgi = shift;
	
    my $path = $cgi -> path_info;

    if ($path eq '/metrics') {
		&getSensors($metarlocations);
	}	
}


