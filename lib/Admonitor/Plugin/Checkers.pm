package Admonitor::Plugin::Checkers;

use strict;
use warnings;

use IO::Async::Loop;
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

    my @plugins = map {
        my $name = "Admonitor::Plugin::Checker::$_";
        eval "require $name";
        $name->new(
            loop   => $self->loop,
            schema => $self->schema,
        );
    } keys %{$self->config};
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

