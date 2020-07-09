#!perl

use strict;
use warnings;

# Set values for the mocked Sys::Statistics::Linux package below
use vars qw( $alarm_sent $fake_realfreeper );
undef $fake_realfreeper;

use Test::More 'no_plan';

# Load the module at runtime to override Sys::Statistics::Linux
require Admonitor::Plugin::Agent::Memory;

my $memory_agent = Admonitor::Plugin::Agent::Memory->new(
    config => { enabled => 1 },
);

my @test = (
    {
        percentage_memory_free => 7,
        expect_alarm => 1,
    },
    {
        percentage_memory_free => 42,
        expect_alarm => 0,
    },
);

foreach my $test_case (@test) {
    my %test_case = %$test_case;
    $fake_realfreeper = $test_case{percentage_memory_free};

    my $memory_data = $memory_agent->read;
    $memory_agent->alarm($memory_data);

    if ( $test_case{expect_alarm} ) {
        is $alarm_sent, 1,
            "Free memory at ${fake_realfreeper}% sent an expected alarm";
    }
    else {
        is $alarm_sent, 0,
            "Free memory at ${fake_realfreeper}% didn't send an expected alarm";
    }
}

done_testing();

sub Admonitor::Plugin::Agent::Memory::send_alarm {
    $alarm_sent = 1;
}

# Mock the system statistics class
package Sys::Statistics::Linux;

sub new { bless {}, __PACKAGE__ }

sub get {
    $main::alarm_sent = 0;
    return $_[0];
}

sub memstats { { realfreeper => $main::fake_realfreeper } }
