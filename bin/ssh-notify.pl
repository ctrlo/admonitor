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

use Admonitor::Config;
use Admonitor::Plugin;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport 'admonitor';
use Mail::Message;
use Net::IP;
use Socket;
use Net::DNS;

Admonitor::Config->instance(
    config => config,
);

my $res = Net::DNS::Resolver->new;

my $guard = schema->txn_scope_guard;

my $logins = rset('SSHLogin')->search({}, {
    group_by  => [qw/username source_ip host_id fingerprint/],
    select => [
        { count => 'datetime', -as => 'count' },
        { max => 'username', -as => 'username' },
        { max => 'source_ip', -as => 'source_ip' },
        { max => 'host_id', -as => 'host_id' },
        { max => 'fingerprint', -as => 'fingerprint' },
    ],
    order_by => 'host_id',
});

my $send; my @logins;

# Produce a lookup hash to signify which users and their groups have
# notification for all SSH logins. These take precedence over a user's
# individual logins
my $notify_all;
foreach my $user (rset('User')->search({ notify_all_ssh => 1 })->all)
{
    foreach my $user_group ($user->user_groups->all)
    {
        foreach my $fingerprint ($user->fingerprints)
        {
            $notify_all->{$fingerprint->fingerprint}->{$user_group->group_id} = 1;
        }
    }
}

foreach my $login ($logins->all)
{
    my $host_id     = $login->get_column('host_id');
    my $count       = $login->get_column('count');
    my $username    = $login->get_column('username');
    my $source_ip   = $login->get_column('source_ip');
    my $fingerprint = $login->get_column('fingerprint');

    my $source_ptr = Net::IP->new($source_ip)->reverse_ip;

    my $reverse = $source_ip;
    if (my $query = $res->query("$source_ptr", "PTR"))
    {
        foreach my $rr ($query->answer) {
            next unless $rr->type eq "PTR";
            $reverse = $rr->rdatastr;
        }
    }

    # Loop through each user that has this fingerprint. De-duplicate logins,
    # such that a user is only notifed once for each login. If a user is in a
    # group for all SSH notifications, then prioritise that and do not send to
    # the user's individual email address in that case. The idea is that a
    # single SSH fingerprint can be in use for multiple users/groups, and that
    # the group takes precedence for notifications.
    my $this_done;
    my @fps = rset('Fingerprint')->search({ fingerprint => $fingerprint})->all;
    @fps = (undef) if !@fps; # Ensure report of fingerprint doesn't match any users
    foreach my $fp (@fps)
    {   my $user = $fp && $fp->user;
        my $name = $user ? $user->firstname." ".$user->surname : 'Unknown';
        my $host = rset('Host')->find($host_id);
        my $hn   = $host->name;

        my $msg = "$count logins for username $username by $name to $hn (from $source_ip [$reverse])";
        foreach my $ug ($host->group->user_groups)
        {
            next unless $ug->user->notify_all_ssh;
            next if $this_done->{$ug->user_id}->{$source_ip};
            push @{$send->{$ug->user_id}}, $msg;
            $this_done->{$ug->user_id}->{$source_ip} = 1;
        }
        if ($user && !$notify_all->{$fingerprint}->{$host->group_id})
        {
            $send->{$user->id} ||= [];
            push @{$send->{$user->id}}, $msg;
        }
    }
}

my $from = Admonitor::Config->instance->config->{admonitor}->{mail_from}
    or panic "Please configure mail_from in config file";

foreach my $user_id (keys %$send)
{
    my $user = rset('User')->find($user_id);
    my $msg = $user->notify_all_ssh
        ? "This email contains all recent SSH logins for hosts in your group.\n\n"
        : "This email contains all your recent SSH logins. If these are not correct please contact the ISMS Manager.\n\n";
    $msg .= join "\n", @{$send->{$user_id}};
    Mail::Message->build(
        From    => $from,
        To      => $user->email,
        Subject => "SSH logins",
        data    => $msg,
    )->send(via => 'sendmail', sendmail_options => [-f => $from]);
}

rset('SSHLogin')->delete;

$guard->commit;
