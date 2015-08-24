package Admonitor::Schema::Result::Host;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('host');
__PACKAGE__->add_columns(
  id => {
    data_type => "integer", is_auto_increment => 1, is_nullable => 0,
  },
  name => {
    data_type => 'varchar',
    size      => 50,
  },
  port => {
    data_type   => 'integer',
    is_nullable => 1,
  },
  password => {
    data_type   => 'varchar',
    size        => 64,
    is_nullable => 1,
  },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->has_many(
  'statvals' => 'Admonitor::Schema::Result::Statval',
  {'foreign.host'=>'self.id'});

1;
