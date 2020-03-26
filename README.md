This is an OpenWeatherMap exporter for Prometheus, it exposes weather metrics.

The config file `/etc/sensors/metar.yml` would look like:

````yaml
metar_base_url: "https://tgftp.nws.noaa.gov/data/observations/metar/stations/"
metar_http_port: "12345"
metar_locations:
  - Elba:
     province: LI
     stationcode: LIRX
     stationgeohash: spx729xc6xu6
  - Pisa:
     province: PI
     stationcode: LIRP
     stationgeohash: spz2s7rdd037

````

http_port is the tcp port where the server will listen

## Install

This script needs perl modules that you can install from cpan

cpanm install HTTP::Server::Simple::CGI
cpanm install base qw(HTTP::Server::Simple::CGI)
cpanm install Config::YAML
cpanm install WWW::Mechanize
cpanm install Geo::METAR
cpanm install CGI
cpanm install Time::Local
cpanm install Data::Dumper
cpanm install Text::Unidecode

Copy the script in /usr/local/sbin/
Make it executable
chmod +x /usr/local/sbin/metar-exporter.pl

## Run

/usr/local/sbin/metar-exporter.pl > /dev/null 2>&1

To stop, kill its PID
