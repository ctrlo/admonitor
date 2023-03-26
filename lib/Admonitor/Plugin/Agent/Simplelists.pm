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

use File::stat;
use Log::Report 'admonitor';
use Moo;

extends 'Admonitor::Plugin::Agent';

my @queues = (
    {
        name => 'approve',
        size => 2,
        age  => 1800,
    },
    {
        name => 'bounce',
        size => 10,
        age  => 1800,
    },
    {
        name => 'incoming',
        size => 2,
        age  => 300,
    },
    {
        name => 'store',
        size => 200,
        age  => 3600,
    },
);

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'queue_count',
                type => 'decimal',
                read => 'max',
            },
            {
                name => 'queue_age',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self   = shift;
    my $values;
    foreach my $q (@queues)
    {
        my $queue = $q->{name};
        my $dir = "/var/lib/simplelists/$queue";
        my $age;
        foreach my $message (glob "$dir/*")
        {
            my $st = stat("$dir/$message") or next;
            my $modified = $st->mtime or next;
            my $a = time - $modified;
            $age = $a
                if !$age || $a > $age;
        }

        $values->{$queue} = {
            count => files_in_dir($dir),
            age   => $age,
        };
    }
    return +{
        queues => $values,
    };
}

sub write
{   my ($self, $data) = @_;
    foreach my $q (@queues)
    {
        my $queue = $q->{name};
        my $value = $data->{queues}->{$queue};
        $self->write_single(
            stattype => 'queue_count',
            param    => $queue,
            value    => $value->{count},
        );
        $self->write_single(
            stattype   => 'queue_age',
            param      => $queue,
            value      => $value->{age},
            allow_null => 1,
        );
    }
}

sub alarm
{   my ($self, $data) = @_;
    foreach my $q (@queues)
    {
        my $queue     = $q->{name};
        # size
        my $threshold = $q->{size};
        my $total     = $data->{queues}->{$queue}->{count};
        $self->send_alarm("More than $threshold files in queue $queue (total $total)")
            if $total > $threshold;
        # age
        $threshold = $q->{age};
        my $age = $data->{queues}->{$queue}->{age};
        $self->send_alarm("Files in queue $queue older than $threshold seconds (age $age)")
            if $age > $threshold;
    }
}

sub files_in_dir
{   my $dir = shift;
    opendir my $dh, $dir or fault "failed to open dir '$dir'";
    scalar grep { -d "$dir/$_" && /^[^\.]+/ } readdir $dh;
}

1;
