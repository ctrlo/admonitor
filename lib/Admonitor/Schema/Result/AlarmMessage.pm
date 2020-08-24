package Admonitor::Schema::Result::AlarmMessage;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('alarm_message');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
    },
    group_id => {
        data_type           => 'integer',
        is_foreign_key      => 1,
        is_nullable         => 0,
    },
    message_suffix => {
        data_type           => 'text',
        is_nullable         => 0,
    },
    plugin => {
        data_type           => 'varchar',
        size                => 50,
        is_nullable         => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'group' => 'Admonitor::Schema::Result::Group',
    {'foreign.id'=>'self.group_id'},
);

1;
