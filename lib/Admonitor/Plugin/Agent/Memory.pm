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

package Admonitor::Plugin::Agent::Memory;

use strict;
use warnings;

use Moo;

extends 'Admonitor::Plugin::Agent';

has maximum_use_percentage => (
    is      => 'ro',
    default => \&_default_maximum_use_percentage,
);

sub _default_maximum_use_percentage {
    my $self = shift;
    my $default_value = $self->schema->resultset('HostAlarm')
        ->search({ host => $self->host_id, plugin => 'Agent::Memory' })
        ->get_column('decimal')
        ->first;
    $default_value //= 80;
    return scalar $default_value;
}

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'realusedper',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self = shift;
    my $lxs = Sys::Statistics::Linux->new(memstats => 1);
    my $stat = $lxs->get;
    {
        maximum_use_percentage => $self->maximum_use_percentage,
        realfreeper => $stat->memstats->{realfreeper},
    };
}

sub write
{   my ($self, $data) = @_;
    $self->write_single(
        stattype => 'realusedper',
        value    => realusedper($data->{realfreeper}),
    );
}

sub alarm
{   my ($self, $data) = @_;
    my $realusedper = realusedper($data->{realfreeper});
    # Old versions of the agent might not send
    # $data->{maximum_use_percentage} to the server, so fall back to the
    # server's configured value.
    my $limit = exists $data->{maximum_use_percentage}
        ? $data->{maximum_use_percentage}
        : $self->maximum_use_percentage;
    $self->send_alarm("Real used memory greater than $limit% ($realusedper%)")
        if $realusedper && $realusedper > $limit;
}

sub realusedper
{   defined $_[0] ? 100 - $_[0] : undef;
}

1;

