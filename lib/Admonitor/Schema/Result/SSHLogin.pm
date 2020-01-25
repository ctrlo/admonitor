package Admonitor::Schema::Result::SSHLogin;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('sshlogin');
__PACKAGE__->add_columns(
  id => {
    data_type => "integer", is_auto_increment => 1, is_nullable => 0,
  },
  host_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  user_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
  username => {
    data_type => 'varchar',
    size      => 50,
  },
  source_ip => {
    data_type => 'varchar',
    size      => 50,
  },
  datetime => {
      data_type   => "datetime",
      is_nullable => 0,
  },
  fingerprint => {
    data_type => 'varchar',
    size      => 64,
  },
);
 
__PACKAGE__->set_primary_key('id');
 
__PACKAGE__->belongs_to(
  'host' => 'Admonitor::Schema::Result::Host',
  {'foreign.id'=>'self.host_id'});

__PACKAGE__->belongs_to(
  'user' => 'Admonitor::Schema::Result::User',
  {'foreign.id'=>'self.user_id'});

1;
