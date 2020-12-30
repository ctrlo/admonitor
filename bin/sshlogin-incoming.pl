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

dispatcher SYSLOG => 'syslog',
    mode     => 'DEBUG',
    flags    => 'pid',
    identity => 'Admonitor',
    facility => 'local0';

my $msg;

try {
    my $fromline = <STDIN>;
    $msg = Mail::Message->read(\*STDIN);

    # Accepted publickey for root from 81.187.7.168 port 59784 ssh2: RSA 52:92:3e:c0:6c:40:9a:5b:f5:c2:6c:d2:0d:50:02:63
    # Accepted publickey for simple from 2001:41c8:51:71b:fcff:ff:fe00:41eb port 60182 ssh2: RSA SHA256:peMgY8E9Q4yjZvRYg2WLAwANTg4dSznotBiHqvnzyvY
    $msg->body =~ /Accepted publickey for ([a-z0-9]+) from ([:\.0-9a-f]+) port.* (.*)$/;
    my ($username, $ip, $fingerprint) = ($1, $2, $3);

    my $host = rset('Host')->search({ name => $msg->sender->host })->next;
    if (!$host)
    {
        trace __x"Not logging SSH login for {host}", host => $msg->sender->host;
        exit;
    }

    foreach my $user (rset('Fingerprint')->search({
        fingerprint => $fingerprint,
    })->all)
    {
        rset('SSHLogin')->create({
            host_id     => $host->id,
            user_id     => $user && $user->user_id,
            username    => $username,
            source_ip   => $ip,
            datetime    => DateTime->now,
            fingerprint => $fingerprint,
        });
    }
};

if ($@)
{
    $@->reportFatal(is_fatal => 0) if $@;
    my $error = __x"Failed to process {msg}", msg => $msg->string;
    report {is_fatal => 0}, ERROR => $error;
#    report {is_fatal=>0}, ERROR => "The username or password was not recognised";
}
