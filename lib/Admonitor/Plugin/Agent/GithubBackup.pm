=pod
Admonitor - Server monitoring software
Copyright (C) 2022 Ctrl O Ltd

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

package Admonitor::Plugin::Agent::GithubBackup;

use strict;
use warnings;

use DateTime;
use Moo;
use File::stat;

extends 'Admonitor::Plugin::Agent';

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'backup_time',
                type => 'string',
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self   = shift;
    # Get modified time of first repo in directory
    my $dir = "/var/backups/github/";
    # Return nothing if any failures, which will cause alarm
    opendir(DIR, $dir)
        or return { backup_time => undef };
    my $modified;
    while (my $file = readdir(DIR))
    {
        next if $file =~ /^\./;
        my $st = stat("$dir$file") or next;
        $modified = $st->mtime or next;
        last; # Assume success
    }
    +{
        backup_time => $modified,
    };
}

sub write
{   my ($self, $data) = @_;
    my $value = $data->{backup_time};
    $self->write_single(
        stattype   => 'backup_time',
        value      => $value,
        allow_null => 1,
    );
}

sub alarm
{   my ($self, $data) = @_;
    my $time = $data->{backup_time};
    if (!$time)
    {
        $self->send_alarm("No time retrieved for most recent Github backup");
        return;
    }
    my $modified = DateTime->from_epoch(epoch => $time);
    if (!$modified)
    {
        $self->send_alarm("Unable to parse last backup epoch: $time");
        return;
    }
    $modified > DateTime->now->subtract(days => 7)
        or $self->send_alarm("Last Github backup was more than 7 days ago ($modified)");
}

1;
