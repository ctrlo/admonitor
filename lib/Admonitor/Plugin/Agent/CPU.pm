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
                name => 'total',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self = shift;
    my $lxs = Sys::Statistics::Linux->new(cpustats => 1);
    sleep 1; # For useful stats, as per pod
    my $stat = $lxs->get;
    # Average across all CPUs
    my $total = $stat->cpustats->{cpu}->{total};
    {
        total => $total,
    };
}

sub write
{   my ($self, $data) = @_;
    $self->write_single(
        stattype => 'total',
        value    => $data->{total},
    );
}

sub alarm
{   my ($self, $data) = @_;
    my $use = $data->{total};
    my $limit = 50;
    $self->send_alarm("CPU usage greater than $limit% ($use%)")
        if $use && $use > $limit;
}

1;
