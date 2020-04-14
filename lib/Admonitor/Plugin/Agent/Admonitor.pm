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

# Special agent to send an alarm when another agent is raising exceptions
package Admonitor::Plugin::Agent::Admonitor;

use strict;
use warnings;

use Moo;

extends 'Admonitor::Plugin::Agent';

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'error_message',
                type => 'string',
                # The read type is not really applicable, but we read by groups
                # so we need to group by something.
                read => 'max',
            },
        ],
    },
);

sub write
{   my ($self, $data) = @_;
    my $value = $data->{error_message};
    $self->write_single(
        stattype => 'error_message',
        value    => $value,
    );
}

sub alarm
{   my ($self, $data) = @_;
    my $message = $data->{error_message};
    $self->send_alarm($message)
        if $message;
}

1;
