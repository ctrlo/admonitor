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

use Log::Report mode => 'DEBUG';
use Dancer2;
use Dancer2::Plugin::DBIC;
use IO::Async::Timer::Periodic;
use Admonitor::Config;
use Admonitor::Plugin::Checkers;

dispatcher SYSLOG => 'syslog',
    flags    => 'pid',
    identity => 'Admonitor',
    facility => 'local0';

# Initiate singleton config class for use in other modules
Admonitor::Config->instance(
    config => config,
);

my $checkers = Admonitor::Plugin::Checkers->new(
    schema => schema,
);

my $loop = $checkers->loop;

foreach my $checker (@{$checkers->all})
{
    $checker->start;
}

my $timer = IO::Async::Timer::Periodic->new(
    interval => 300,
    on_tick  => sub {
        foreach my $checker (@{$checkers->all})
        {
            $checker->write;
        }
   },
);
$timer->start;
$loop->add( $timer );

# Catch any exceptions and then restart loop so that the overall process doesn't die
while (1)
{
    try { $loop->run };
    $@->reportAll(is_fatal => 0);
    sleep 60; # Throttle continuous exceptions
}
