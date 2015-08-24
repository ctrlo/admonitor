package Admonitor::Plugin;

use strict;
use warnings;

use Admonitor::Hosts;
use DateTime::Format::Strptime;
use Moo;

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

sub write_single
{   my ($self, $stattype, $param, $value) = @_;

    $self->schema->resultset('Statval')->create({
        datetime => $self->datetime,
        host     => $self->host_id,
        plugin   => $self->name,
        stattype => $stattype,
        decimal  => $value,
        param    => $param,
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

    my $hosts = Admonitor::Hosts->new(
        schema => $self->schema,
    );

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

has name => (
    is => 'lazy',
);

sub _build_name
{   my $self = shift;
    my $name = ref $self;
    $name =~ s/.*::(.*::.*)/$1/;
    $name;
}

1;

