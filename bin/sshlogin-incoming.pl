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
    $msg->body =~ /Accepted publickey for ([a-z0-9]+) from ([:\.0-9a-f]+) port/;
    my ($username, $ip) = ($1, $2);

    my $host = rset('Host')->search({ name => $msg->sender->host })->next;
    if (!$host)
    {
        trace __x"Not logging SSH login for {host}", host => $msg->sender->host;
        exit;
    }

    rset('SSHLogin')->create({
        host_id   => $host->id,
        username  => $username,
        source_ip => $ip,
        datetime  => DateTime->now,
    });
};

if ($@)
{
    $@->reportFatal(is_fatal => 0) if $@;
    my $error = __x"Failed to process {msg}", msg => $msg->string;
    report {is_fatal => 0}, ERROR => $error;
#    report {is_fatal=>0}, ERROR => "The username or password was not recognised";
}
