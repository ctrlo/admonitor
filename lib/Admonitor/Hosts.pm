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

has _index => (
    is => 'lazy',
);

sub _build__index
{   my $self = shift;
    my %index = map { $_->id => $_ } @{$self->all};
    \%index;
}

sub host
{   my ($self, $id) = @_;
    $self->_index->{$id};
}

1;

