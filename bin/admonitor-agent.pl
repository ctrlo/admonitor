#!/usr/bin/perl

use strict;
use warnings;

use Config::Any;
use DBI;
use File::Temp qw/ tempfile /;
use IO::Socket::SSL;
use Cpanel::JSON::XS;
use Log::Report 'admonitor';
use Sys::Hostname;
use threads;

dispatcher SYSLOG => 'syslog', facility => 'local0';

my $cf = '/etc/admonitor/agent.yaml';

-f $cf
    or failure "Unable to read configuration file: $cf";

my $configf = Config::Any->load_files(
    {
        files   => [$cf],
        use_ext => 1,
    }
)->[0];

my ($config) = values %$configf;

my $db = {
    dsn     => $config->{dsn} || "dbi:SQLite:dbname=/tmp/admonitor.sqlite",
    options => {
        AutoCommit => 1,
        RaiseError => 1,
    },
};

my $dbh = DBI->connect($db->{dsn},"","", $db->{options});
setup_db($dbh);

my @agent_names = @{$config->{agents} || []}
    or error "No agents configured";

threads->create(sub {
    # Use separate DB connection for this thread
    my $dbh = DBI->connect($db->{dsn},"","", $db->{options});

    my @agents = map {
        my $name = "Admonitor::Plugin::Agent::$_";
        eval "require $name";
        panic $@ if $@; # Report somewhere useful if checker can't be loaded
        $name->new;
    } @agent_names;
    while (1)
    {
        my $sth  = $dbh->prepare("INSERT INTO records (retrieved) VALUES (0)");
        _execute($sth);
        my $record_id = $dbh->func('last_insert_rowid');
        $sth  = $dbh->prepare(qq/INSERT INTO "values" (record_id, plugin, key, value) VALUES (?,?,?,?)/);
        foreach my $agent (@agents)
        {
            my $values = $agent->read;
            foreach my $key (keys %$values)
            {
                _execute($sth, $record_id, "$agent", $key, encode_json { value => $values->{$key} });
            }
        }
        sleep ($config->{read_interval} || 300);
    }
});

my $ssl_config = $config->{ssl}
    or error "SSL not configured";

my $server = IO::Socket::SSL->new(
    LocalPort     => $config->{port} || 9099,
    Listen        => 10,
    SSL_ca_file   => $ssl_config->{ca_file},
    SSL_cert_file => $ssl_config->{cert_file},
    SSL_key_file  => $ssl_config->{key_file},
) or failure "Failed to listen: $SSL_ERROR";

my $password = $config->{password};
defined $password or error "No password configured"; # Allow blank password

while (1) {
    my $client;
    unless ($client = $server->accept)
    {
        say STDERR "Failed to accept or ssl handshake: $! $SSL_ERROR";
        next;
    }
    
    chomp (my $pw = <$client>);
    if ($pw eq $password)
    {
        say $client 'OK';
    }
    else {
        say STDERR "Invalid password: $password";
        next;
    }

    my $sth = $dbh->prepare("SELECT rowid, datetime FROM records WHERE retrieved = 0 ORDER BY datetime");
    _execute($sth);
    my @stats;
    my ($datemin, $datemax);
    while (my $row = $sth->fetchrow_hashref)
    {
        my $sth2 = $dbh->prepare(qq/SELECT plugin, key, value FROM "values" WHERE record_id=?/);
        _execute($sth2, $row->{rowid});
        while (my $values = $sth2->fetchrow_hashref)
        {
            $datemin = $row->{datetime} if !$datemin;
            $datemax = $row->{datetime};
            push @stats, {
                datetime => $row->{datetime},
                $values->{plugin} => {
                    $values->{key} => decode_json($values->{value})->{value},
                },
            };
        }
    }
    my $serverdata = encode_json({
        records  => \@stats,
        hostname => $config->{hostname} || hostname,
    });
    $sth = $dbh->prepare("UPDATE records SET retrieved = 1 WHERE datetime >= ? AND datetime <= ?");
    _execute($sth, $datemin, $datemax) if $datemin && $datemax;
    print $client "$serverdata \n";
}  
  
$server->close();  

sub setup_db
{   my $dbh = shift;
    $dbh->do(q(
        CREATE TABLE IF NOT EXISTS records (
            datetime DATETIME DEFAULT CURRENT_TIMESTAMP,
            retrieved SMALLINT DEFAULT 0
        )
    ));

    $dbh->do(q(
        CREATE TABLE IF NOT EXISTS "values" (
            record_id INT,
            plugin TEXT,
            key TEXT,
            value TEXT
        )
    ));
}

# Thread safe version, which retries if another execution is making the
# database busy
sub _execute
{   my ($sth, @bind) = @_;
    my $exec = 1;
    while ($exec)
    {
        try {
            $sth->execute(@bind);
        };
        if ($@)
        {
            $@->reportFatal(is_fatal => 0);
            sleep 3;
        }
        else {
            $exec = 0;
        }
    }
}
