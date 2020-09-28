package Admonitor::Plugin::Agent::UFW;

use strict;
use warnings;

use Moo;
extends 'Admonitor::Plugin::Agent';

our $check_command = q(sudo ufw status | head -1 | grep -q '^Status: active$');

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
    system $check_command;
    my $success = $? ? 0 : 1;
    return { enabled => $success };
}

sub write {
    my ($self, $data) = @_;
    $self->write_single(
        stattype => 'enabled',
        value    => $data->{enabled},
    );
}

sub alarm {
    my ($self, $data) = @_;

    if ( $data->{enabled} != 1 ) {
        $self->send_alarm('UFW is not enabled');
    }
}

1;
