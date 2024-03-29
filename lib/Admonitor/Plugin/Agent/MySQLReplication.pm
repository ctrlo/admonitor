=pod
Admonitor - Server monitoring software
Copyright (C) 2020 Ctrl O Ltd

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

package Admonitor::Plugin::Agent::MySQLReplication;

use strict;
use warnings;

use DBI;
use Log::Report;
use Moo;

extends 'Admonitor::Plugin::Agent';

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'replication_running',
                type => 'decimal',
                read => 'min',
            },
            {
                name => 'replication_delay',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

sub read
{   my $self   = shift;

    my $config = $self->config;
    # GRANT REPLICATION CLIENT ON *.* TO 'repcheck'@'localhost' IDENTIFIED BY 'xxx';
    # Later versions:
    # GRANT SLAVE MONITOR ON *.* TO 'repcheck'@'localhost' IDENTIFIED BY 'xxx';
    my $dbh = DBI->connect($config->{dsn}, $config->{username}, $config->{password})
        or error $DBI::errstr;

    my $res = $dbh->selectrow_hashref("SHOW SLAVE STATUS"); # Dies with exception if fails
    my $running = $res->{Slave_SQL_Running} eq 'Yes' && $res->{Slave_IO_Running} eq 'Yes';
    my $delay   = $res->{Seconds_Behind_Master};

    +{
        replication_running => $running,
        replication_delay   => $delay,
    };
}

sub write
{   my ($self, $data) = @_;
    foreach my $stattype (@{$self->stattypes})
    {
        my $name = $stattype->{name};
        next unless exists $data->{$name};
        # There will be no value if replication is not running, and undef
        # values cannot be written
        my $value = $data->{$name};
        if ($name eq 'replication_delay')
        {
            next if !defined $value || $value eq '';
        }
        elsif ($name = 'replication_running')
        {
            $value = $value ? 1 : 0;
        }
        $self->write_single(
            stattype => $name,
            param    => undef, # Not used
            value    => $value,
        );
    }
}

sub alarm
{   my ($self, $data) = @_;
    if (exists $data->{replication_running})
    {
        my $exists = $data->{replication_running};
        $self->send_alarm("MySQL replication has failed")
            if !$exists;
    }
    if (exists $data->{replication_delay})
    {
        my $limit = $self->thresholds->{replication_delay}->{$self->host_id}
            // 600;
        my $delay = $data->{replication_delay};
        $self->send_alarm("MySQL replication is lagging by $delay seconds")
            if defined $delay && $delay > $limit;
    }
}

1;
