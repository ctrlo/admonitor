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

use FindBin;
use lib "$FindBin::Bin/../lib";

use Log::Report 'admonitor';
use Dancer2;
use Dancer2::Plugin::DBIC;
use IO::Async::Listener;
use IO::Async::Timer::Periodic;
use Net::SSLeay 1.83; # Fixes memory leak
use Admonitor::Config;
use Admonitor::Plugin::Checkers;
use Socket qw/IPPROTO_TCP/;

dispatcher SYSLOG => 'syslog',
    mode     => 'DEBUG',
    flags    => 'pid',
    identity => 'Admonitor',
    facility => 'local0';

# Initiate singleton config class for use in other modules
Admonitor::Config->instance(
    config => config,
);

# Catch any exceptions and then restart loop so that the overall process doesn't die
while (1)
{
    # Don't collect non-fatal messages in the try block, as we could be running
    # for a long time and there might be a large number.
    try { _run() } accept => 'ERROR,FAULT,FAILURE,PANIC', on_die => 'PANIC';
    $@->reportAll(is_fatal => 0);
    notice __"Restarting admonitor service after failure";
    sleep 60; # Throttle continuous exceptions
}

sub _run
{
    my $checkers = Admonitor::Plugin::Checkers->new(
        schema => schema,
    );

    my $loop = $checkers->loop;

    foreach my $checker (@{$checkers->all})
    {
        $checker->start;
    }

    # Set up a socket for other admonitor servers to ping and check that this
    # admonitor checker process is alive
    my $server = IO::Async::Listener->new(
        on_stream => sub {
            my (undef, $stream) = @_;
            $stream->configure(
                on_read => sub {
                    my ($self, $buffref, $eof) = @_;
                    my $received = $$buffref;
                    $received =~ /ping/i
                        or return;
                    $self->write("Pong\n",
                        on_error => sub {
                            my ($self, $errno) = @_;
                            warning "Failed to write pong: {err}", err => $errno;
                        },
                    );
                    $$buffref = "";
                    return 0;
                },
            );
            $loop->add($stream);
       },
    );

    $loop->add($server);

    $server->listen(addr => {
        family   => 'inet',
        socktype => 'stream',
        protocol => IPPROTO_TCP,
        port     => 9098,
    })->get;

    my $timer = IO::Async::Timer::Periodic->new(
        interval => 300,
        on_tick  => sub {
            foreach my $checker (@{$checkers->all})
            {
                $checker->write;
            }
       },
    );
    $timer->start;
    $loop->add( $timer );
    # See logging comments above
    try { $loop->run } accept => 'ERROR,FAULT,FAILURE,PANIC', on_die => 'PANIC';
    my $e = $@;
    $_->remove_all_notifiers foreach @{$checkers->all};
    $loop->remove($timer);
    $loop->remove($server);
    $e->reportAll;
}
