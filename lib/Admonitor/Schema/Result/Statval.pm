package Admonitor::Schema::Result::Statval;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table('statval');
__PACKAGE__->add_columns(
  id => {
    data_type => "integer", is_auto_increment => 1, is_nullable => 0,
  },
  datetime => {
    data_type => 'datetime',
  },
  stattype => {
    data_type => 'varchar',
    size      => 50,
  },
  host => {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  plugin => {
    data_type => 'varchar',
    size      => 50,
  },
  decimal => {
    data_type => 'decimal',
    size      => [ 10, 2 ],
  },
  param => {
    data_type   => 'varchar',
    size        => 50,
    is_nullable => 1,
  },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->belongs_to(
  'host' => 'Admonitor::Schema::Result::Host',
  {'foreign.id'=>'self.host'});
 
1;
