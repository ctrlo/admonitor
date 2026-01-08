#!/usr/bin/env perl

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;
my $config = config;

use DBIx::Class::Migration;
use Dancer2::Plugin::LogReport 'linkspace', mode => 'NORMAL';
use Getopt::Long;

my ($prepare, $install, $upgrade, $downgrade, $status);

GetOptions (
    'prepare'    => \$prepare,
    'install'    => \$install,
    'upgrade'    => \$upgrade,
    'downgrade'  => \$downgrade,
    'status'     => \$status,
) or exit;

$prepare || $install || $upgrade || $downgrade || $status
    or error "Please specify --prepare, --install, --status or --upgrade";

my $db_settings = $config->{plugins}{DBIC}{default}
    or panic "configuration file structure changed.";

my @app_connect = (
    $db_settings->{dsn},
    $db_settings->{user},
    $db_settings->{password},
    {
        quote_names => 1,
        RaiseError  => 1,
    },
);

my $migration = DBIx::Class::Migration->new(
    schema_class => 'Admonitor::Schema',
    schema_args  => \@app_connect,
    target_dir => "$FindBin::Bin/../share",
    dbic_dh_args => {
        force_overwrite => 1,
        quote_identifiers => 1,
        databases => ['MySQL', 'PostgreSQL'],
        sql_translator_args => {
            producer_args => {
                mysql_version => 5.7,
            },
        },
    },
);

if ($prepare)
{ $migration->prepare }
elsif ($install)
{ $migration->install }
elsif ($upgrade)
{ $migration->upgrade }
elsif ($downgrade)
{ $migration->downgrade }
elsif ($status)
{ $migration->status }
