#!/usr/local/bin/perl -w

use lib '/usr/local/netdisco';
use SNMP::Info;

my $host = shift || 'commcat';
my $comm = shift || 'public';
my $ver  = shift || 2;
my $debug  = shift || 1;


my $dev = new SNMP::Info(
            AutoSpecify => 1,
            Debug       => $debug,
            DestHost    => $host,
            Community   => $comm,
            Version     => $ver
                        )
    or die;

die "Hmmm. $dev->error()\n" if $dev->error(1);


my $name = $dev->name();
print "$name\n";
my $interfaces = $dev->interfaces();

my $store = $dev->store();
print "store has ", scalar(keys(%$store)), " keys.\n";

$dev->clear_cache();

$store = $dev->store();
print "store has ", scalar(keys(%$store)), " keys.\n";

$name = $dev->name();
print "$name\n";
$interfaces = $dev->interfaces();

$store = $dev->store();
print "store has ", scalar(keys(%$store)), " keys.\n";
