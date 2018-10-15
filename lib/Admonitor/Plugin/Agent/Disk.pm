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

package Admonitor::Plugin::Agent::Disk;

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
                name => 'usageper',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self  = shift;
    my $lxs   = Sys::Statistics::Linux->new(diskusage => 1);
    my $stat  = $lxs->get;
    my $value = $stat->diskusage;
    {
        diskusage => $value,
    };
}

sub write
{   my ($self, $data) = @_;

    foreach my $disk (keys %{$data->{diskusage}})
    {
        my $value = $data->{diskusage}->{$disk};
        $self->write_single(
            stattype => 'usageper',
            param    => $disk,
            value    => $value->{usageper},
        ) if $value->{usageper} > 0;
    }
}

sub alarm
{   my ($self, $data) = @_;
    my $usage = $data->{diskusage};
    my $sent;
    foreach my $disk (keys %$usage)
    {
        my $value = $usage->{$disk}->{usageper};
        $sent ||= $self->send_alarm("Disk space usage for $disk greater than 75% ($value%)")
            if $value && $value > 75;
    }
    return $sent; # Return whether alarm has been sent to prevent duplicates
}

1;

