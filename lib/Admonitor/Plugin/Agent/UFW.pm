package Admonitor::Plugin::Agent::UFW;

use strict;
use warnings;

use IPC::Run qw( run timeout );
use Log::Report 'admonitor';

use Moo;
extends 'Admonitor::Plugin::Agent';

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'enabled',
                type => 'decimal',
                read => 'min',
            },
        ],
    },
);

sub read {

    my ($in, $out, $err);
    # Ensure timeout in case sudo hangs for a password
    run [qw/sudo ufw status/], \$in, \$out, \$err, timeout(5)
        or fault "Failed to run sudo command";

    my $success = $out =~ /^Status: active$/m ? 1 : 0;
    return { enabled => $success };
}

sub write_agent
{   my ($self, $host, $datetime, $data) = @_;
    $self->write_single(
        stattype => 'enabled',
        host     => $host,
        datetime => $datetime,
        value    => $data->{enabled},
    );
}

sub alarm
{   my ($self, $host, $data) = @_;

    if ( $data->{enabled} != 1 ) {
        $self->send_alarm($host, 'UFW is not enabled');
    }
}

1;
