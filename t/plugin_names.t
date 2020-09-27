use strict;
use warnings;

use Test::More tests => 3;

require_ok 'Admonitor::Plugin::Agent::OpenDKIM';
my $agent = Admonitor::Plugin::Agent::OpenDKIM->new;
is $agent->name, 'Agent::OpenDKIM', 'An agent has its expected name';

# See below for this example checker's implementation
my $checker = Admonitor::Plugin::Checker::Example->new;
is $checker->name, 'Checker::Example', 'A checker has its expected name';


package Admonitor::Plugin::Checker::Example;

use Moo;
BEGIN { extends 'Admonitor::Plugin'; }
