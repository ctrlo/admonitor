package Admonitor::Schema::ResultSet::User;
  
use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

use Log::Report 'simplelists';

use Moo;

sub BUILDARGS { $_[2] || {} } # For Moo

sub active
{   my $self = shift;
    # Possibly addition of conditions in the future (e.g. deleted)
    $self;
}

1;
