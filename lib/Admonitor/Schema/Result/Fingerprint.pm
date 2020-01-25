package Admonitor::Schema::Result::Fingerprint;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('fingerprint');
__PACKAGE__->add_columns(
  id => {
    data_type => "integer", is_auto_increment => 1, is_nullable => 0,
  },
  user_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  fingerprint => {
    data_type => 'varchar',
    size      => 64,
  },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->belongs_to(
  'user' => 'Admonitor::Schema::Result::User',
  {'foreign.id'=>'self.user_id'});

1;
