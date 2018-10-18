#!/usr/bin/perl

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

use strict;
use warnings;
use feature 'say';

use FindBin;
use lib "$FindBin::Bin/../lib";

use Admonitor::Plugin;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport 'admonitor';
use Mail::Message;
use Net::IP;
use Socket;
use Net::DNS;

my $res = Net::DNS::Resolver->new;

my $guard = schema->txn_scope_guard;

my $logins = rset('SSHLogin')->search({}, {
    group_by  => [qw/username source_ip host_id/],
    select => [
        { count => 'datetime', -as => 'count' },
        { max => 'username', -as => 'username' },
        { max => 'source_ip', -as => 'source_ip' },
        { max => 'host_id', -as => 'host_id' },
    ],
    order_by => 'host_id',
});

my %group_send; my @logins;
my $last_host_id;
foreach my $login ($logins->all)
{
    my $host_id = $login->get_column('host_id');
    if ($last_host_id && $host_id != $last_host_id)
    {
        my $host = rset('Host')->find($last_host_id);
        $group_send{$host->group_id} ||= [];
        push @{$group_send{$host->group_id}}, {
            host   => $host,
            logins => [@logins], # copy array for ref
        };
        @logins = ();
    }
    my $count      = $login->get_column('count');
    my $username   = $login->get_column('username');
    my $source_ip  = $login->get_column('source_ip');
    my $source_ptr = Net::IP->new($source_ip)->reverse_ip;

    my $reverse = $source_ip;
    if (my $query = $res->query("$source_ptr", "PTR"))
    {
        foreach my $rr ($query->answer) {
            next unless $rr->type eq "PTR";
            $reverse = $rr->rdatastr;
        }
    }

    push @logins, "$count logins for username $username from $source_ip ($reverse)";
    $last_host_id = $host_id;
}

# Repeated code from above
my $host = rset('Host')->find($last_host_id);
$group_send{$host->group_id} ||= [];
push @{$group_send{$host->group_id}}, {
    host   => $host,
    logins => [@logins], # copy array for ref
};

foreach my $group_id (keys %group_send)
{
    my $msg = '';
    foreach my $set (@{$group_send{$group_id}})
    {
        $msg .= $set->{host}->name . ":\n";
        foreach my $login (@{$set->{logins}})
        {
            $msg .= "$login\n";
        }
        $msg .= "\n";
    }

    my $group = rset('Group')->find($group_id);
    foreach my $user_group ($group->user_groups)
    {
        my $msg = Mail::Message->build(
            To      => $user_group->user->email,
            Subject => "SSH logins",
            data    => $msg,
        )->send(via => 'sendmail');
    }
}

rset('SSHLogin')->delete;

$guard->commit;
