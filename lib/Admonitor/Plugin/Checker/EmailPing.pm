=pod
Admonitor - Server monitoring software
Copyright (C) 2024 Ctrl O Ltd

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

# An email ping checker. Sends emails and expects to receive a copy back
package Admonitor::Plugin::Checker::EmailPing;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw/HashRef/;

extends 'Admonitor::Plugin::Checker';

use AE;
use DateTime;
use IO::Async::Timer::Periodic;
use Linux::Inotify2;
use Log::Report 'admonitor';
use Mail::Box::Manager;
use Math::NumberCruncher;
use Net::Async::SMTP::Client 0.004; # Contains memory leak fix
use POSIX qw(floor);
use Scalar::Util qw(weaken);
use Session::Token;

has stattypes => (
    is      => 'ro',
    default => sub {
        [
            {
                name => 'delay',
                type => 'decimal',
                read => 'max',
            },
        ],
    },
);

has io_object => (
    is => 'lazy',
);

my $mbox = "/var/lib/admonitor/email_ping/incoming";

has email_sender => (
    is => 'lazy',
);

sub _build_email_sender
{   my $self = shift;
    $self->config->{sender}
        or panic "Sending email address needs to be defined";
}

has email_recipient => (
    is => 'lazy',
);

sub _build_email_recipient
{   my $slef = shift;
    $self->config->{recipient}
        or panic "Recipient email address needs to be defined";
}

sub _build_io_object
{   my $that = shift;
    -d $mbox
        or error "Mbox file does not exist for incoming emails";

    # There doesn't seem to be a native inotify module for IO::Async
    my $inotify = new Linux::Inotify2
        or fault "unable to create new inotify object";

    $inotify->watch ("$mbox/new", IN_CREATE, sub {
        # Not needed, kept for reference
        my $e = shift;
        my $filename = $e->fullname;

        my $mgr    = Mail::Box::Manager->new;
        # remove_when_empty parameter only needed for mbox file
        my $folder = $mgr->open(folder => $mbox, access => 'rw', remove_when_empty => 0);
        my $count = 0;
        foreach my $msg ($folder->messages)
        {
            my $body = $msg->body->decoded;
            if ($body =~ /^([0-9]+) TOKEN ([0-9a-z]{32})$/mi)
            {
                my $host_id = $1;
                my $token   = $2;
                trace __x"Message received for host ID {host}", host => $host_id;
                if (!$that->results->{$host_id}->{$token})
                {
                    # It's possible that the SMTP send will not finish
                    # cleanly and thus the message will not be recorded at
                    # this end, but it might still be delivered and thus
                    # returned here
                    warning __x"No existing message found for token {token}",
                        token => $token;
                    next;
                }
                $that->results->{$host_id}->{$token}->{received} = time;
                $folder->message($count)->delete;
                $count++;
            }
            else {
                warning __x"No token found in msg {msgid}", msgid => $msg->messageId;
            }
        }
        $folder->write;
        $folder->close
            or error "Couldn't write mail folder: $!\n";
    });

    # Automatically adds to the IO::Async loop
    AE::io $inotify->fileno, 0, sub { $inotify->poll };
}

has smtp_objects => (
    is      => 'ro',
    isa     => HashRef,
    builder => sub { +{} },
);

sub _build_smtp
{   my $self = shift;
}

has results => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_results
{   my $self = shift;
    my $results;
    $results->{$_->id} = {}
        foreach @{$self->hosts};
    return $results;
}

has failcount => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_failcount
{   my $self = shift;
    my $failcount;
    $failcount->{$_->id} = 0
        foreach @{$self->hosts};
    return $failcount;
}

has timers => (
    is  => 'lazy',
    isa => HashRef,
);

sub _get_smtp
{   my ($self, $host) = @_;
    my $smtp = Net::Async::SMTP::Client->new(host => $host->name);
    $self->add_notifier($smtp);
    $smtp;
}

sub _build_timers
{   my $self = shift;
    weaken $self;
    my $timers = {};
    foreach my $host (@{$self->hosts})
    {
        $timers->{$host->id} = IO::Async::Timer::Periodic->new(
            interval       => 60,
            first_interval => $self->first_interval,
            on_tick        => sub {
                my $timer = shift;
                my $host_id = $host->id;
                my $token = Session::Token->new(length => 32)->get;
                my $msg = Mail::Message->build(
                    To             => $self->email_recipient,
                    From           => $self->email_sender,
                    Subject        => "Admonitor test",
                    data           => "$host_id TOKEN $token",
                );
                my $msgtext  = $msg->string;
                my ($sender) = $msg->sender;
                my ($to)     = $msg->to;
                my $smtp     = $self->_get_smtp($host);
                $timer->adopt_future(
                    $smtp->connected
                        ->then(sub {
                            $smtp->send(to => $to->address, from => $sender->address, data => $msgtext);
                        })
                        ->on_done(sub {
                            my $response = shift;
                            trace __x"Sent token message to host {host}", host => $host->name;
                            $self->results->{$host->id}->{$token} = {
                                sent => time,
                            };
                        })
                        ->on_fail(sub {
                            # Seems to return different parameters depending on
                            # context. See calls to fail() in Protocol::SMTP::Client
                            # So print everything:
                            my $error = join '; ', @_;
                            warning __x"Failed to send email to host {host}: {error}",
                                host => $host->name, error => $error;
                            $self->failcount->{$host->id}++;
                        #})->then_with_f(sub {
                        })->on_ready(sub {
                            $self->remove_notifier($smtp);
                        })->else_done
                    );
            },
        ),
    };
    return $timers;
}

my $alarm_seconds = 900;

sub write
{   my ($self, $data) = @_;

    foreach my $host (@{$self->hosts})
    {
        my %tokens = %{$self->results->{$host->id}};

        # Total number sent (success plus failed to sent)
        my $total_sent = %tokens + $self->failcount->{$host->id};
        if (!$total_sent)
        {
            my $hostname = $host->name;
            $self->send_alarm("Failed to send any test emails for host $hostname");
            next;
        }

        my $failcount;

        # First process tokens that have been successfully sent
        my @times;
        foreach my $token (keys %tokens)
        {
            my $msg           = $self->results->{$host->id}->{$token};
            my $sent_time     = $msg->{sent};
            my $received_time = $msg->{received};

            if ($received_time)
            {
                # In time?
                push @times, $received_time - $sent_time;
                delete $self->results->{$host->id}->{$token};
            }
            else {
                # Overdue? Count as a failure if so
                my $delay = DateTime->now->epoch - $sent_time;
                $failcount++
                    if $delay > $alarm_seconds;
            }
        }

        # Now any problems with the sending
        $failcount += $self->failcount->{$host->id};

        $self->host_id($host->id);

        # Check delays
        my $avg = int Math::NumberCruncher::Mean(\@times);
        $self->send_alarm("Email delivery took $avg seconds")
            if $avg > $alarm_seconds;

        # Check complete failures
        my $failavg = int (($failcount / $total_sent) * 100);
        $self->send_alarm("Email delivery failures higher than 25% ($failavg%)")
            if $failavg > 25;

        $self->write_single(
            stattype   => 'delay',
            value      => $avg, # Can be undef if none received successfully
            failcount  => $failcount,
            allow_null => 1,
        );

        $self->failcount->{$host->id} = 0;
    }
}

1;
