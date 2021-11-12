#!/usr/bin/env perl
use strict;
use warnings;

use DateTime;
use Log::Report     qw(admonitor);

# Common modules
use POSIX            qw/strftime/;
use English          qw/$UID/;
use Errno            qw/EEXIST/;
use Fcntl            qw/:DEFAULT :mode/;
use IO::File         ();

=head1 NAME

incoming - maildrop for SSH logins

=head1 SYNOPSYS

 incoming <message

=head1 DESCRIPTION

This script is used to collect incoming SSH logins.  The mailrobot will
handle those message one after the other (when it runs as daemon
and is looking at the same queue directory!)

=cut

# Auto-config
# is HOME set when called from postfix? Probably not, but required by config.
my $user   = $ENV{USER} ||= (getpwuid $UID )[0];
my $home   = $ENV{HOME} ||= (getpwnam $user)[7];

dispatcher SYSLOG => 'syslog',
    mode     => 'DEBUG',
    flags    => 'pid',
    identity => 'Admonitor',
    facility => 'local0';

# The incoming queue
my $queue = "/var/lib/admonitor/sshlogin";

# Error messages can be sent back to senders, so don't put path information etc
# in them
-d $queue
    or error "incoming queue does not exist";

# Create a unique file for this message
my $filename;
my $now = DateTime->now->strftime("%Y%m%d-%T");

# XXXX This is a bit messy, but how to do it better?
# Need to ensure that the file name chosen is not already
# in use as a .proc
# I tried adding the following before the if defined statement, but for
# an unknown reason it causes the "if defined $file" to return false:
#
#    if (-e "$filename.proc")
#    {   $file->close;
#        next UNIQUE;
#    }
#    last if defined $file;
#

umask 0027; # Don't allow any user to see file as it's written

# Use the index director to ensure unique files. Empty files are created here
# to "hold" the name, and deleted on completion.
my $unique = '001';
my $file;
UNIQUE:
for( ; ; $unique++ )
{   $filename = "$now-$unique";

    # O_EXCL not safe over NFS3, but that does not really hurt because
    # usually only one mailrobot will be active.
    $file = IO::File->new("$queue/$filename", O_RDWR|O_CREAT|O_EXCL); #, S_IWUSR|S_IRUSR);

    last if defined $file;

    my $rc    = $!;
    next UNIQUE if $rc==EEXIST;

    fault __x"Cannot create file {file} in queue", file => "$queue/$filename";
}

while(my $line = <STDIN> )
{   $line =~ s/\r\n/\n/;     # remove optional CR
    last if $line eq "\n";   # end of header?

    $file->print($line);
}

while(my $line = <STDIN> )
{   $line =~ s/\r\n/\n/;     # remove optional CR
    $file->print($line);
}

$file->flush;
if($file->error)
{   unlink "$queue/$filename";
    fault "errors while writing $file";
}

unless(chmod S_IRUSR|S_IRGRP, "$queue/$filename")
{   unlink "$queue/$filename";
    fault "cannot chmod $file";
}

$file->close;
