=pod
Admonitor - Server monitoring software
Copyright (C) 2018 Ctrl O Ltd

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

package Admonitor::Plugin::Agent::Simplelists;

use strict;
use warnings;

use Log::Report 'admonitor';
use Moo;

extends 'Admonitor::Plugin::Agent';

my @queues = qw(approve bounce incoming store);

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'queue_count',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self   = shift;
    my $values;
    foreach my $queue (@queues)
    {
        $values->{$queue} = files_in_dir("/var/lib/simplelists/$queue");
    }
    return +{
        queue_count => $values,
    };
}

sub write
{   my ($self, $data) = @_;
    foreach my $queue (@queues)
    {
        my $value = $data->{queue_count}->{$queue};
        $self->write_single(
            stattype => 'queue_count',
            param    => $queue,
            value    => $value,
        );
    }
}

sub alarm
{   my ($self, $data) = @_;
    my %threshold = (
        approve  => $self->thresholds->{queue_count}->{$self->host_id} || 2,
        incoming => $self->thresholds->{queue_count}->{$self->host_id} || 2,
        store    => $self->thresholds->{queue_count}->{$self->host_id} || 100,
    );
    foreach my $queue (@queues)
    {
        my $threshold = $threshold{$queue} || 10;
        my $total     = $data->{queue_count}->{$queue};
        $self->send_alarm("More than $threshold files in queue $queue (total $total)")
            if $total > $threshold;
    }
}

sub files_in_dir
{   my $dir = shift;
    opendir my $dh, $dir or fault "failed to open dir '$dir'";
    grep { -d "$dir/$_" && /^[^\.]+/ } readdir $dh;
}

1;
