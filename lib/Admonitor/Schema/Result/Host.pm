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
  group_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
  silenced => {
    data_type     => 'smallint',
    default_value => 0,
    is_nullable   => 0,
  },
  collect_agents => {
    data_type     => 'smallint',
    default_value => 1,
    is_nullable   => 0,
  },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->has_many(
  'statvals' => 'Admonitor::Schema::Result::Statval',
  {'foreign.host'=>'self.id'});

__PACKAGE__->has_many(
  'host_checkers' => 'Admonitor::Schema::Result::HostChecker',
  {'foreign.host'=>'self.id'});

__PACKAGE__->belongs_to(
  'group' => 'Admonitor::Schema::Result::Group',
  {'foreign.id'=>'self.group_id'},
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

1;
