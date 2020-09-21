package Admonitor::Schema::Result::User;
 
use strict;
use warnings;
 
use base qw/DBIx::Class::Core/;
 
__PACKAGE__->table('user');
__PACKAGE__->add_columns(
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    firstname => {
        data_type   => 'text',
        is_nullable => 1,
    },
    surname => {
        data_type   => 'text',
        is_nullable => 1,
    },
    email => {
        data_type   => 'varchar', # For easy mysql index
        size        => 128,
        is_nullable => 0,
    },
    username => {
        data_type   => 'varchar', # For easy mysql index
        size        => 128,
        is_nullable => 0,
    },
    password => {
        data_type   => 'varchar',
        size        => 128,
        is_nullable => 1,
    },
    pwchanged => {
        data_type   => "datetime",
        is_nullable => 1,
    },
    pw_reset_code => {
        data_type   => "char",
        is_nullable => 1,
        size        => 32
    },
    lastlogin => {
        data_type   => "datetime",
        is_nullable => 1,
    },
    notify_all_ssh => {
        data_type     => "smallint",
        default_value => 0,
        is_nullable   => 0,
    },
    web_enabled => {
        data_type     => "boolean",
        default_value => 0,
        is_nullable   => 0,
    },
);
 
__PACKAGE__->set_primary_key('id');
 
sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'user_idx_email', fields => [ 'email' ]);
    $sqlt_table->add_index(name => 'user_idx_username', fields => [ 'username' ]);
}

1;
