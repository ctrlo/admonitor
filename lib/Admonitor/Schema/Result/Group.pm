package Admonitor::Schema::Result::Group;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('group');
__PACKAGE__->add_columns(
  id => {
    data_type => "integer", is_auto_increment => 1, is_nullable => 0,
  },
  name => {
    data_type => 'varchar',
    size      => 50,
  },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->has_many(
  'user_groups' => 'Admonitor::Schema::Result::UserGroup',
  {'foreign.group_id'=>'self.id'});

__PACKAGE__->might_have(
    alarm_message => 'Admonitor::Schema::Result::AlarmMessage',
    { 'foreign.group_id' => 'self.id'},
);

1;
