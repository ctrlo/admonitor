package Admonitor::Plugin;

use strict;
use warnings;

use Admonitor::Hosts;
use DateTime::Format::Strptime;
use Log::Report 'admonitor';
use Mail::Message;
use Moo;

use overload '""'  => '_as_string';

# datetime and host_id are used to store the relevant values
# for the record about to be written. They are not passed in
# with write_single() so that the values are not needed by
# the plugin (keeps the plugin code to a minimum).
has datetime => (
    is => 'rw',
);

has host_id => (
    is => 'rw',
);

# Used for logging
has host_name => (
    is => 'ro',
    default => sub { 'UNKNOWN' },
);

sub write_single
{   my ($self, %options) = @_;

    my $stattype = $options{stattype}
        or panic __x"stattype parameter missing for write_single in {plugin}",
            plugin => $self->name;

    # Work out what value this particular stattype is
    my %types = map { $_->{name} => $_ } @{$self->stattypes};
    # Convert to full type
    $stattype = $types{$stattype};

    my $value = $options{value};

    if (!defined $value && !$options{allow_null})
    {
        warning __x"Not writing undefined value for '{stattype}' in plugin '{plugin}' on host '{host}'. ".
            "Use allow_null option to override.",
            stattype => $stattype, plugin => $self->name, host => $self->host_name;
        return;
    }
    my $type_write = $stattype->{type};
    $self->schema->resultset('Statval')->create({
        datetime    => $self->datetime,
        host        => $self->host_id,
        plugin      => $self->name,
        stattype    => $stattype->{name},
        param       => $options{param},
        failcount   => $options{failcount},
        $type_write => $value,
    });
}

has start => (
    is     => 'rw',
    coerce => sub {
        my $strp = DateTime::Format::Strptime->new( pattern   => '%F' );
        $strp->parse_datetime($_[0]);
    },
);

has end => (
    is     => 'rw',
    coerce => sub {
        my $strp = DateTime::Format::Strptime->new( pattern   => '%F' );
        $strp->parse_datetime($_[0]);
    },
);

has _hosts => (
    is => 'lazy',
);

sub _build__hosts
{   my $self = shift;
    my $hosts = Admonitor::Hosts->new(
        schema => $self->schema,
    );
}

has graph_data => (
    is => 'lazy',
);

sub _build_graph_data
{   my $self = shift;

    my $end   = $self->end   || DateTime->now( time_zone => 'floating' );
    my $start = $self->start || $end->clone->subtract( days => 1 );

    # Format DateTime objects for the database query
    my $from_db = $self->schema->storage->datetime_parser->format_date($start);
    my $to_db   = $self->schema->storage->datetime_parser->format_date($end->add( days => 1));

    # Calculate how many readings to extract from DB and group accordingly
    my $group = [
        'param',
        $self->schema->resultset('Statval')->dt_SQL_pluck({ -ident => '.datetime' }, 'year'),
        $self->schema->resultset('Statval')->dt_SQL_pluck({ -ident => '.datetime' }, 'month'),
        $self->schema->resultset('Statval')->dt_SQL_pluck({ -ident => '.datetime' }, 'day_of_month'),
    ];
    my $diff = $start->subtract_datetime( $end );
    push @$group, $self->schema->resultset('Statval')->dt_SQL_pluck({ -ident => '.datetime' }, 'hour')
        unless $diff->months || $diff->years; # Less than a month

    my $hosts = $self->_hosts;
    my @series;

    foreach my $host (@{$hosts->all})
    {
        foreach my $stattype (@{$self->stattypes})
        {
            my $readdisp = $self->schema->resultset('Statval')->search({
                datetime => {
                    '-between' => [
                        $from_db, $to_db
                    ]
                },
                stattype => $stattype->{name},
                plugin   => $self->name,
                host     => $host->id,
            },{
                'select' => [
                    {
                        $stattype->{read} => $stattype->{type},
                        -as               => $stattype->{name},
                    },
                    {
                        max => 'datetime',
                        -as => 'datetime'
                    },
                    {
                        max => 'param',
                        -as => 'param'
                    },
                ],
                group_by => $group,
            });

            my $values; 
            while (my $r = $readdisp->next)
            {
                my $param = $r->param || 'param1';
                $values->{$param} ||= [];
                push @{$values->{$param}}, {
                    x => $r->datetime->epoch * 1000,
                    y => int $r->get_column($stattype->{name}),
                };
            }

            push @series, map {
                {
                    label => $host->name." ($_)",
                    data  => $values->{$_},
                }
            } keys %$values;
        }
    }
    \@series;
}

# Default handler for no alarm condition in plugin
sub alarm {}

sub send_alarm
{   my ($self, $error) = @_;
    my $host = $self->schema->resultset('Host')->find(
        $self->host_id,
        { prefetch => { group => { user_groups => 'user' } } },
    );
    my $hostname = $host->name;
    my $group = $host->group;
    my $body = "An alarm was received for host $hostname: $error";
    foreach my $user_group ($group->user_groups)
    {
        my $alarm_message = $self->schema->resultset('AlarmMessage')->find(
            { group_id => $group->id, plugin => $self->name }
        );
        if ( defined $alarm_message ) {
            $body .= "\n\n" . $alarm_message->message_suffix;
        }
        my $msg = Mail::Message->build(
            To      => $user_group->user->email,
            Subject => "Admonitor alarm",
            data    => $body,
        )->send(via => 'sendmail');
    }
    1; # Report that an alarm has been sent
}

has name => (
    is => 'lazy',
);

sub _build_name
{   my $self = shift;
    my $name = ref $self;
    $name =~ s/.*::(.*::.*)/$1/;
    $name;
}

sub _as_string { $_[0]->name; }

1;

