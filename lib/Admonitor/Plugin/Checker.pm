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
use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef/;

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

has hosts => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_hosts
{   my $self = shift;
    my $search = $self->config->{all_hosts} ? {} : { 'host_checkers.name' => $self->name };
    my @hosts = $self->schema->resultset('Host')->search($search,{
        join => 'host_checkers'
    })->all;
    [@hosts];
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
        $self->loop->add($timer);
    }
    $self->loop->add( $self->io_object );
}

1;

