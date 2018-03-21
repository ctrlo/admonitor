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
    my @plugins = map {
        my $name = "Admonitor::Plugin::Checker::$_";
        eval "require $name";
        panic $@ if $@; # Report somewhere useful if checker can't be loaded
        $name->new(
            loop   => $self->loop,
            schema => $self->schema,
        );
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

