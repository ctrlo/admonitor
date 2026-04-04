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

package Admonitor::Plugin::Checker::WWW;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw/HashRef/;

extends 'Admonitor::Plugin::Checker';

use IO::Async::Timer::Periodic;
use Log::Report 'admonitor';
use Net::Async::HTTP;
use Math::NumberCruncher;
use Scalar::Util qw(weaken);
use Net::SSLeay 1.88; # Contains memory leak fix

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
    my $ua = Net::Async::HTTP->new(
        fail_on_error => 1,
        timeout       => 5,
        # Count a redirect as a success (see comments below) to ensure accurate
        # timing
        max_redirects => 0,
    );
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
    my $t0 = [Time::HiRes::gettimeofday];
    my $host_name = $host->name;

    $self->io_object->GET('https://' . $host_name)
        ->on_done(sub {
            my $response = shift;
            # Count a redirect as a success, on the basis that many web hosts
            # perform a redirect (e.g. to a login screen) or to another host
            # (if the host name requested is not the corect one). From
            # experience, it is very unlikely that a redirect is actually the
            # sign of failure.
            if ($response->is_success || $response->is_redirect)
            {
                push @{$self->results->{$host->id}},
                    Time::HiRes::tv_interval($t0);
            }
            else {
                assert __x"Failed to make WWW request to {host}: unexpected response: {code}",
                    host => $host_name, code => $response->code;
                $self->failcount->{$host->id}++;
            }
        })
        ->on_fail(sub {
            my $failure = shift;
            assert "Failed to make WWW request to $host_name: $failure";
            $self->failcount->{$host->id}++;
        })
        ->else_done;
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
            $self->send_alarm("WWW failure higher than 25% ($failavg%)")
                if $failavg > 25;
        }
        $self->failcount->{$host->id} = 0;
        $self->results->{$host->id} = [];
    }
}

1;

