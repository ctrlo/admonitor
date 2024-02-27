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

has timers => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_timers
{   my $self = shift;
    weaken $self;
    my $timers = {};
    foreach my $host (@{$self->hosts})
    {
        $timers->{$host->id} = IO::Async::Timer::Periodic->new(
            interval => 1,
            on_tick  => sub {
                $timers->{$host->id}->adopt_future(
                    $self->io_object->ping($host->name)
                        ->on_done(sub {
                            push @{$self->results->{$host->id}}, $_[0];
                        })
                        ->on_fail(sub {
                            $self->failcount->{$host->id}++;
                        })
                        ->else_done
                );
           },
        ),
    };
    return $timers;
}

sub write
{   my ($self, $data) = @_;

    foreach my $host (@{$self->hosts})
    {
        my $failcount = $self->failcount->{$host->id};
        my $avg = Math::NumberCruncher::Mean($self->results->{$host->id});
        $self->host_id($host->id);
        $self->write_single(
            stattype   => 'time',
            value      => $avg,
            failcount  => $failcount,
            allow_null => 1,
        );
        if (my $sent = @{$self->results->{$host->id}} + $failcount)
        {
            my $failavg = int (($failcount / $sent) * 100);
            $self->send_alarm("Ping failure higher than 20% ($failavg%)")
                if $failavg > 20;
        }
        $self->failcount->{$host->id} = 0;
        $self->results->{$host->id} = [];
    }
}

1;

