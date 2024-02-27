package Admonitor::Plugin::Checkers;

use strict;
use warnings;

use IO::Async::Loop;
use Log::Report 'admonitor';
use Moo;

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
    $global->{admonitor}->{plugins}->{checkers};
}


has all => (
    is => 'lazy',
);

sub _build_all
{   my $self = shift;

    my @names = grep { $self->config->{$_}->{enabled} } keys %{$self->config};
    # Start all the checkers at intervals, so that they are all not running at
    # the same time. In theory this shouldn't matter, but there seems little
    # point in having them all running together for a few seconds, rather than
    # spreading out the CPU cycles
    my $interval = 0;
    # Interval could be reduced if more checkers needed
    panic "Unable to spread out this number of checkers"
        if @names > 6;
    my @plugins = map {
        my $name = "Admonitor::Plugin::Checker::$_";
        eval "require $name";
        panic $@ if $@; # Report somewhere useful if checker can't be loaded
        my $p = $name->new(
            loop           => $self->loop,
            schema         => $self->schema,
            first_interval => $interval,
        );
        $interval += 10;
        $p;
    } @names;
    \@plugins;
}

has loop => (
    is => 'lazy',
);

sub _build_loop
{   my $self = shift;
    IO::Async::Loop->new;
}

1;

