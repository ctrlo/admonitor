#!/usr/bin/env perl
 
use Test::Most tests => 5;
 
use_ok 'Admonitor::Schema';
use_ok 'Admonitor::Plugin';
use_ok 'Admonitor::Plugin::Checker';
warning_like { use_ok 'Admonitor' }
    qr/\ANo Auth::Extensible realms configured with which to authenticate user\b/,
    'Expected warning when loading Admonitor';
