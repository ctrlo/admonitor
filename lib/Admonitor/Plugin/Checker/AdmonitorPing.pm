=pod
Admonitor - Server monitoring software
Copyright (C) 2025 Ctrl O Ltd

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

package Admonitor::Plugin::Checker::AdmonitorPing;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw/HashRef/;

extends 'Admonitor::Plugin::Checker';

use IO::Async::Stream;
use IO::Async::Timer::Periodic;
use Log::Report 'admonitor';
use Math::NumberCruncher;
use Scalar::Util qw(weaken);
use Time::HiRes qw/time/;

my $timeout = 10;
my $interval = 5;

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
            interval => $interval,
            first_interval => $self->first_interval,
            on_tick => sub {
                my $stream = IO::Async::Stream->new(
                    on_read => sub {
                        return 0;
                    },
                    # Not sure if the folllowing error handlers do anything with the
                    # async code below
                    on_write_error => sub {
                        warning __x"Failed to write data to {host} for admonitor ping",
                            host => $host->name;
                    },
                    on_read_error => sub {
                        warning "Failed to read data from {host} for admonitor ping",
                            host => $host->name;
                    },
                );
                $self->add_notifier($stream);

                my $connect_future = $stream->connect(
                    addr => {
                        family   => "inet",
                        socktype => "stream",
                        port     => 9098,
                        ip       => $host->name,
                    },
                    on_fail => sub {
                        warning __x"Failed to connect to {host}", host => $host->name;
                    },
                );

                $connect_future = Future->wait_any(
                    $connect_future,
                    $self->loop->timeout_future(after => $timeout)->transform(fail => sub {
                        warning __x"Timed out connecting for admonitor ping from {host}",
                            host => $host->name;
                    })
                );

                my $start = time;
                $timers->{$host->id}->adopt_future($connect_future
                    ->then(sub {
                            trace __x"Admonitor ping connected to {host}", host => $host->name;
                    })
                    ->on_done(sub {
                        my $response = shift;
                        trace __x"Writing to {host} for admonitor ping",
                            host => $host->name;
                        $stream->write("Ping\n", on_error => sub {
                            my ($self, $err) = @_;
                            warning __x"Failed to write data to {host} for admonitor ping: {err}",
                                host => $host->name, err => $err;
                        });
                    })
                    ->on_fail(sub {
                        warning __x"Failed to connect to {host} for admonitor ping",
                            host => $host->name;
                        $self->failcount->{$host->id}++;
                    })
                    ->then(sub {
                        trace __x"Admonitor ping waiting for data from {host}", host => $host->name;
                        my $future_read = $stream->read_until("\n");
                        # Add timeout
                        Future->wait_any($future_read,
                            $self->loop->timeout_future(after => $timeout)
                            ->transform(fail => sub {
                                warning __x"Timed out waiting for admonitor ping response from {host}",
                                    host => $host->name;
                            }),
                        );
                    })->then(sub {
                        my $buffer = shift;
                        my $duration = time - $start;
                        if ($buffer =~ /pong/i)
                        {
                            trace __x"Received admonitor ping for host {host} time {time}",
                                host => $host->name, time => $duration;
                            push @{$self->results->{$host->id}}, $duration;
                        }
                    })->followed_by(sub {
                        $self->remove_notifier($stream);
                    })->else_done
                );
            },
        );
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
            my $limit = $self->thresholds->{fail_percent}->{$self->host_id}
                // 20;
            $self->send_alarm("Admonitor failure higher than 20% ($failavg%)")
                if $failavg > $limit;
        }
        $self->failcount->{$host->id} = 0;
        $self->results->{$host->id} = [];
    }
}

1;

