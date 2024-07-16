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

package Admonitor::Plugin::Agent::CPU;

use strict;
use warnings;

use Moo;
use Sys::Statistics::Linux;

extends 'Admonitor::Plugin::Agent';

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'avg_15',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self = shift;
    my $lxs = Sys::Statistics::Linux->new(loadavg => 1);
    my $stat = $lxs->get;
    my $load = $stat->loadavg; # Force hashref return
    {
        loadavg => $load,
    };
}

sub write
{   my ($self, $data) = @_;
    $self->write_single(
        stattype => 'avg_15',
        value    => $data->{loadavg}->{avg_15},
    );
}

sub alarm
{   my ($self, $data) = @_;
    my $use = $data->{loadavg}->{avg_15};
    my $limit = 25;
    $self->send_alarm("CPU usage greater than $limit% ($use%)")
        if $use && $use > $limit;
}

1;
