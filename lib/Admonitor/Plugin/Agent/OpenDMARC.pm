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

package Admonitor::Plugin::Agent::OpenDMARC;

use strict;
use warnings;

use IO::Socket::UNIX;
use Moo;

extends 'Admonitor::Plugin::Agent';

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'socket_exists',
                type => 'decimal',
                read => 'min',
            },
        ],
    },
);

sub read
{   my $self   = shift;

    my $sock_path = "/var/run/opendmarc/opendmarc.sock";

    my $exists = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Peer => $sock_path,
    );

    +{
        socket_exists => $exists ? 1 : 0,
    };
}

sub write
{   my ($self, $data) = @_;
    my $value = $data->{socket_exists};
    $self->write_single(
        stattype => 'socket_exists',
        param    => undef, # Not used
        value    => $value,
    );
}

sub alarm
{   my ($self, $data) = @_;
    my $exists = $data->{socket_exists};
    $self->send_alarm("OpenDMARC socket does not exist")
        if !$exists;
}

1;
