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

package Admonitor::Plugin::Agent::Duplicity;

use strict;
use warnings;

use DateTime;
use Log::Report 'admonitor';
use Moo;
use File::Slurp qw/read_file/;

extends 'Admonitor::Plugin::Agent';

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'backup_status',
                type => 'string',
                # The read type is not really applicable, but we read by groups
                # so we need to group by something. The status will be
                # consistent for several hours, so this shouldn't matter
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self = shift;
    my $file = "/etc/duplicity/verify";
    warning "Duplicity verification file does not exist"
        if ! -f $file;
    warning "Duplicity verification file not readable"
        if ! -r $file;
    my $contents = -r $file ? read_file($file) : undef;
    +{
        backup_status => $contents,
    };
}

sub write
{   my ($self, $data) = @_;
    my $value = $data->{backup_status};
    $self->write_single(
        stattype => 'backup_status',
        value    => $value,
    );
}

sub alarm
{   my ($self, $data) = @_;
    my $status = $data->{backup_status};
    $self->send_alarm("No backup verification information")
        if !$status;
    my $parsed = $self->parse_backup_status($status);
    return $self->send_alarm("Backup verification failed: $status")
        if !$parsed || !$parsed->{identical};
    return $self->send_alarm("Backup verification not within 30 hours")
        # Returns 30 hours for 30 hours and something, hence greater than or equal
        if DateTime->now->delta_ms($parsed->{time})->in_units('hours') >= 30;
}

sub parse_backup_status
{   my ($self, $status) = @_;

    if ($status =~ m!^File (.*) retrieved at (.*) with differences(.*)and /root/testfile (differ|are identical)\s?$!s)
    {
        my $params = {};
        $params->{identical} = $4 eq 'are identical';
        my $time = $2;
        if ($time && $time =~ /^[0-9]+$/)
        {
            $params->{time} = DateTime->from_epoch(epoch => $time);
        }
        return $params;
    }
}

1;
