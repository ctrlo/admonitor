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

use IO::Socket::SSL;
use JSON;
use Dancer2;
use Dancer2::Plugin::DBIC;

my @hosts = rset('Host')->all;

foreach my $host (@hosts)
{
    my $alarms; # Stop multiple alarms
    my $client = IO::Socket::SSL->new(
        SSL_ca_file  => config->{admonitor}->{ssl}->{ca_file},
        PeerHost     => $host->name,
        PeerPort     => $host->port || config->{admonitor}->{default_port} || 9099,
    )
        or die "$! SSL error=$SSL_ERROR";

    print $client $host->password."\n";
    <$client> eq "OK\n"
        or die "Authentication failed";

    my $serverdata = decode_json <$client>;

    my @plugins = map {
        my $name = "Admonitor::Plugin::Agent::$_";
        eval "require $name";
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
