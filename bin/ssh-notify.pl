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
    group_by  => [qw/username source_ip host_id user_id/],
    select => [
        { count => 'datetime', -as => 'count' },
        { max => 'username', -as => 'username' },
        { max => 'source_ip', -as => 'source_ip' },
        { max => 'host_id', -as => 'host_id' },
        { max => 'user_id', -as => 'user_id' },
    ],
    order_by => 'host_id',
});

my $send; my @logins;
my $last_host_id; my $last_user_id;
foreach my $login ($logins->all)
{
    my $host_id   = $login->get_column('host_id');
    my $user_id   = $login->get_column('user_id');
    my $count     = $login->get_column('count');
    my $username  = $login->get_column('username');
    my $source_ip = $login->get_column('source_ip');

    my $source_ptr = Net::IP->new($source_ip)->reverse_ip;

    my $reverse = $source_ip;
    if (my $query = $res->query("$source_ptr", "PTR"))
    {
        foreach my $rr ($query->answer) {
            next unless $rr->type eq "PTR";
            $reverse = $rr->rdatastr;
        }
    }

    my $user = $user_id && rset('User')->find($user_id);
    my $name = $user ? $user->firstname." ".$user->surname : 'Unknown';
    my $host = rset('Host')->find($host_id);
    my $hn   = $host->name;

    my $msg = "$count logins for username $username by $name to $hn (from $source_ip [$reverse])";
    if ($user_id)
    {
        $send->{$user_id} ||= [];
        push @{$send->{$user_id}}, $msg;
    }
    foreach my $ug ($host->group->user_groups)
    {
        next unless $ug->user->notify_all_ssh;
        push @{$send->{$ug->user_id}}, $msg
            unless $user_id && $user_id == $ug->user_id; # Already pushed in previous statement
    }
}

foreach my $user_id (keys %$send)
{
    my $user = rset('User')->find($user_id);
    my $msg = $user->notify_all_ssh
        ? "This email contains all recent SSH logins for hosts in your group.\n\n"
        : "This email contains all your recent SSH logins. If these are not correct please contact the ISMS Manager.\n\n";
    $msg .= join "\n", @{$send->{$user_id}};
    Mail::Message->build(
        To      => $user->email,
        Subject => "SSH logins",
        data    => $msg,
    )->send(via => 'sendmail');
}

rset('SSHLogin')->delete;

$guard->commit;
