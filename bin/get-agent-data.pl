#!/usr/bin/perl

=pod
Admonitor - Server monitoring software
Copyright (C) 2015 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Log::Report 'admonitor';
use Dancer2;
use Dancer2::Plugin::DBIC;
use IO::Socket::SSL;
use IO::Socket::Timeout;
use Errno qw(ETIMEDOUT EWOULDBLOCK);

my @hosts = rset('Host')->all;

foreach my $host (@hosts)
{
    trace __x"Processing {host}", host => $host->name;
    try { do_host($host) };
    if (my $exception = $@->wasFatal)
    {
        $exception->throw(is_fatal => 0);
    }
    else {
        $@->reportAll;
    }
}


sub do_host
{   my $host = shift;

    my $alarms; # Stop multiple alarms

    # Allow SSL fingerprint to override only connections where verification
    # unsuccessful
    if (config->{admonitor}->{ssl}->{fingerprint})
    {
        IO::Socket::SSL::set_args_filter_hack( sub {
            my ($is_server,$args) = @_;
            if ( ! $is_server ) {
                # client settings - enable verification with default CA
                # and fallback hostname verification etc
                delete @{$args}{qw(
                    SSL_verify_mode
                    SSL_ca_file
                    SSL_ca_path
                    SSL_verifycn_scheme
                    SSL_version
                )};
                # and add some fingerprints for known certs which are signed by
                # unknown CAs or are self-signed
                $args->{SSL_fingerprint} = config->{admonitor}->{ssl}->{fingerprint};
            }
        });
    }

    my $client = IO::Socket::SSL->new(
        SSL_ca_file  => config->{admonitor}->{ssl}->{ca_file},
        PeerHost     => $host->name,
        PeerPort     => $host->port || config->{admonitor}->{default_port} || 9099,
        Timeout      => 5,
    ) or failure __x"Unable to connect to {host}: $SSL_ERROR", host => $host->name;

    # Set up timeouts on the actual data exchange (otherwise may hang indefinitely)
    IO::Socket::Timeout->enable_timeouts_on($client);
    $client->read_timeout(5);
    $client->write_timeout(5);

    print $client $host->password."\n";
    my $response = <$client>;
    if (!$response && ( 0+$! == ETIMEDOUT || 0+$! == EWOULDBLOCK )) {
        error __x"Timeout reading data from {host} during authentication", host => $host->name;
    }
    $response eq "OK\n"
        or error __x"Authentication failed for host {host}", host => $host->name;

    $response = <$client>;
    if (!$response && ( 0+$! == ETIMEDOUT || 0+$! == EWOULDBLOCK )) {
        error __x"Timeout reading data from {host} during data exchange", host => $host->name;
    }
    my $serverdata = decode_json $response;

    # Bork if no data received - likely there is a problem
    error __x"No data received from {host}", host => $host->name
        if !@{$serverdata->{records}};

    my @plugins = map {
        my $name = "Admonitor::Plugin::Agent::$_";
        eval "require $name";
        panic $@ if $@; # Report somewhere useful if checker can't be loaded
        $name->new(
            schema => schema,
        );
    } keys %{config->{admonitor}->{plugins}->{agents}};

    foreach my $record (@{$serverdata->{records}})
    {
        my $time    = $record->{datetime};

        foreach my $plugin (@plugins)
        {
            my $data = $record->{$plugin->name}
                or next;
            $plugin->datetime($time);
            $plugin->host_id($host->id);
            $plugin->write($data);
            $alarms->{$plugin} = 1
                if !$alarms->{$plugin} && $plugin->alarm($data);
        }
    }

    $client->close();
}
