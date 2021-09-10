package Admonitor::Schema;
 
use strict;
use warnings;
 
use parent 'DBIx::Class::Schema';
 
our $VERSION = 14;
 
Admonitor::Schema->load_namespaces(
   default_resultset_class => 'ResultSet',
);
 
1;
