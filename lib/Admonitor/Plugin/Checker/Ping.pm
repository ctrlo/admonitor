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

#
# The following is needed for this checker to work:
#
# echo "0 1000" > /proc/sys/net/ipv4/ping_group_range
#

package Admonitor::Plugin::Checker::Ping;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw/HashRef/;

extends 'Admonitor::Plugin::Checker';

use IO::Async::Timer::Periodic;
use Net::Async::Ping;
use Math::NumberCruncher;
use Scalar::Util qw(weaken);

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'time',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

has '+interval' => (
    default => 1,
);

has io_object => (
    is => 'lazy',
);

sub _build_io_object
{   my $self = shift;
    Net::Async::Ping->new('icmp');
}

has results => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_results
{   my $self = shift;
    my $results;
    $results->{$_->id} = []
        foreach @{$self->hosts};
    return $results;
}

has failcount => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_failcount
{   my $self = shift;
    my $failcount;
    $failcount->{$_->id} = 0
        foreach @{$self->hosts};
    return $failcount;
}

sub checker_future
{   my ($self, $timer, $host) = @_;
    weaken $self;
    $self->io_object->ping($host->name)
        ->on_done(sub {
            push @{$self->results->{$host->id}}, $_[0];
        })
        ->on_fail(sub {
            $self->failcount->{$host->id}++;
        })
        ->else_done
}

sub write_checker
{   my $self = shift;

    foreach my $host (@{$self->hosts})
    {
        my $failcount = $self->failcount->{$host->id};
        my $avg = Math::NumberCruncher::Mean($self->results->{$host->id});
        $self->write_single(
            stattype   => 'time',
            host       => $host,
            value      => $avg,
            failcount  => $failcount,
            allow_null => 1,
        );
        if (my $sent = @{$self->results->{$host->id}} + $failcount)
        {
            my $failavg = int (($failcount / $sent) * 100);
            my $limit = $self->thresholds->{fail_percent}->{$self->host_id}
                // 20;
            $self->send_alarm($host, "Ping failure higher than 20% ($failavg%)")
                if $failavg > $limit;
        }
        $self->failcount->{$host->id} = 0;
        $self->results->{$host->id} = [];
    }
}

1;

