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

package Admonitor::Plugin::Checker;

use Admonitor::Config;
use DateTime;
use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef Int/;

extends 'Admonitor::Plugin';

has schema => (
    is       => 'ro',
    required => 1,
);

has config => (
    is => 'lazy',
);

sub _build_config
{   my $self = shift;
    my $global = Admonitor::Config->instance->config;
    my ($short_name) = $self->name =~ /::([a-z]+)/i;
    $global->{admonitor}->{plugins}->{checkers}->{$short_name};
}

has loop => (
    is       => 'ro',
    required => 1,
);

has first_interval => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

has _notifiers => (
    is      => 'ro',
    default => sub { +{} },
);

sub add_notifier
{   my ($self, $notifier) = @_;
    $self->_notifiers->{"$notifier"} = $notifier;
    $self->loop->add($notifier);
}

sub remove_notifier
{   my ($self, $notifier) = @_;
    $self->loop->remove($notifier);
    delete $self->_notifiers->{"$notifier"};
}

sub remove_all_notifiers
{   my $self = shift;
    foreach my $notifier (keys %{$self->_notifiers})
    {
        $self->loop->remove($self->_notifiers->{$notifier});
        delete $self->_notifiers->{$notifier};
    }
}

has hosts => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_hosts
{   my $self = shift;
    my $rs = $self->schema->resultset('Host');
    $rs = $rs->search({
        'host_checkers.name' => $self->name,
    },{
        join => 'host_checkers'
    }) unless $self->config->{all_hosts};
    my @hosts = $rs->all
        or error __x"No hosts defined for {plugin}. If this is intentional please remove from config",
            plugin => $self->name;
    \@hosts;
}

# Used in Agents for the datetime of each datum. For checkers, we
# just use the current time whenever we write
sub datetime
{   my $self = shift;
    DateTime->now;
}

sub start
{   my $self = shift;

    foreach (@{$self->hosts})
    {
        my $timer = $self->timers->{$_->id};
        $timer->start;
        $self->add_notifier($timer);
    }
    my $notifier = $self->io_object;
    # Do not need to add if it is another event object, such as EV
    $self->add_notifier($notifier)
        if $notifier->isa("IO::Async::Notifier");
}

1;

