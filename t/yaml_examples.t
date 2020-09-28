#!perl

use strict;
use warnings;

my @file;
BEGIN {
    @file = qw(
        config.yml-example
        etc/agent.yaml
    );
}

use Test::Most tests => scalar @file;
use YAML 'LoadFile';

lives_ok { LoadFile($_) } "$_ contains valid YAML" foreach @file;
