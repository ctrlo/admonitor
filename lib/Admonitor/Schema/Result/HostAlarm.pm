package Admonitor::Schema::Result::HostAlarm;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('host_alarm');
__PACKAGE__->add_columns(
  id => {
    data_type => "integer", is_auto_increment => 1, is_nullable => 0,
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
    data_type   => 'decimal',
    size        => [ 10, 3 ],
  },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->belongs_to(
  'host' => 'Admonitor::Schema::Result::Host',
  {'foreign.id'=>'self.host'});
 
sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'host_alarm_idx_host', fields => ['host']);
}

1;
