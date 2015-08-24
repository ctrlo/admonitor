package Admonitor::Hosts;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef/;

has schema => (
    is       => 'ro',
    required => 1,
);

has all => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_all
{   my $self = shift;

    my @hosts = $self->schema->resultset('Host')->all;
    \@hosts;
}

1;

