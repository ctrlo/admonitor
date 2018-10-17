package Admonitor::Schema::Result::UserGroup;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('user_group');
__PACKAGE__->add_columns(
    id => {
      data_type => "integer", is_auto_increment => 1, is_nullable => 0,
    },
    user_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    group_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->belongs_to(
  'group' => 'Admonitor::Schema::Result::Group',
  {'foreign.id'=>'self.group_id'});

__PACKAGE__->belongs_to(
  'user' => 'Admonitor::Schema::Result::User',
  {'foreign.id'=>'self.user_id'});

1;
