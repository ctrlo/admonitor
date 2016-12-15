package Admonitor::Schema::Result::HostChecker;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('host_checker');
__PACKAGE__->add_columns(
  id => {
    data_type => "integer", is_auto_increment => 1, is_nullable => 0,
  },
  name => {
    data_type => 'varchar',
    size      => 50,
  },
  host => {
      data_type      => "integer",
      is_foreign_key => 1,
      is_nullable    => 0,
    },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->belongs_to(
  'host' => 'Admonitor::Schema::Result::Host',
  {'foreign.id'=>'self.host'});

1;
