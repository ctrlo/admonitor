#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use DateTime;
use Log::Report 'admonitor';
use Mail::Message;
use Dancer2;
use Dancer2::Plugin::DBIC;
use Fcntl            qw/:DEFAULT :mode/;

dispatcher SYSLOG => 'syslog',
    mode     => 'DEBUG',
    flags    => 'pid',
    identity => 'Admonitor',
    facility => 'local0';

my $queue_in = "/var/lib/admonitor/sshlogin";

while(1)
{   my @msgdirs = glob "$queue_in/*";
    my $sleep   = 5;

    foreach my $msgfile (@msgdirs)
    {
        next unless -f $msgfile;

        # Check read permissions. If not readable file is not yet ready
        my $mode = (stat($msgfile))[2]
            or next;
        ($mode & S_IRUSR) >> 6 or next;

        next if $msgfile =~ m/[\.err|\.proc]$/;

        # Prevent message being processed multiple times
        rename $msgfile, "$msgfile.proc" or next;

        my $opened = open my $in, '<:raw', "$msgfile.proc";
        unless ($opened)
        {   alert __x"Could not open file {file}", file => "$msgfile.proc";
            rename "$msgfile.proc", "$msgfile.err";
            next;
        }

        <$in>;   # skip From line
        my $msg = Mail::Message->read($in);

        try { _process($msg) };
        if ($@)
        {
            $@->reportFatal(is_fatal => 0);
            my $error = __x"Failed to process {msg}", msg => $msg->string;
            report {is_fatal => 0}, ERROR => $error;
        }
        trace "Processed: $msgfile";
        unlink "$msgfile.proc";
    }
    sleep $sleep;
}


sub _process
{   my $msg = shift;

    # Accepted publickey for root from 81.187.7.168 port 59784 ssh2: RSA 52:92:3e:c0:6c:40:9a:5b:f5:c2:6c:d2:0d:50:02:63
    # Accepted publickey for simple from 2001:41c8:51:71b:fcff:ff:fe00:41eb port 60182 ssh2: RSA SHA256:peMgY8E9Q4yjZvRYg2WLAwANTg4dSznotBiHqvnzyvY
    $msg->body =~ /Accepted publickey for ([a-z0-9]+) from ([:\.0-9a-f]+) port.* (.*)$/;
    my ($username, $ip, $fingerprint) = ($1, $2, $3);

    my $host = rset('Host')->search({ name => $msg->sender->host })->next;
    if (!$host)
    {
        trace __x"Not logging SSH login for {host}", host => $msg->sender->host;
        return;
    }

    my $fp_rs = rset('Fingerprint')->search({
        'me.fingerprint'       => $fingerprint,
        'user_groups.group_id' => $host->group_id,
    },{
        join => {
            user => 'user_groups',
        },
    });
    rset('SSHLogin')->create({
        host_id     => $host->id,
        username    => $username,
        source_ip   => $ip,
        datetime    => DateTime->now,
        fingerprint => $fingerprint,
    }) if !$fp_rs->count;
    foreach my $user ($fp_rs->all)
    {
        rset('SSHLogin')->create({
            host_id     => $host->id,
            user_id     => $user->user_id,
            username    => $username,
            source_ip   => $ip,
            datetime    => DateTime->now,
            fingerprint => $fingerprint,
        });
    }
};

