package Admonitor::Plugin::Agents;

use strict;
use warnings;

use Moo;

has config => (
    is       => 'ro',
    required => 1,
);

has schema => (
    is       => 'ro',
    required => 1,
);

has all => (
    is => 'lazy',
);

sub _build_all
{   my $self = shift;

    my @plugins = map {
        my $name = "Admonitor::Plugin::Agent::$_";
        eval "require $name";
        $name->new(
            schema => $self->schema,
        );
    } keys %{$self->config->{admonitor}->{plugins}->{agents}};
    \@plugins;
}

1;

