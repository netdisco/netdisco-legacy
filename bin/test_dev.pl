#!/usr/local/bin/perl -w

use lib qw(/usr/local/netdisco);

use SNMP::Info;

my $host = shift || 'commcat';
my $comm = shift || 'public';
my $debug  = shift || 0;
my $ver    = shift || 2;

print "Connecting to $host\n";
my $dev = new SNMP::Info( 
                          'AutoSpecify' => 1,  
                          'AutoVerBack' => 1,
                          'Version'     => $ver,
                          'Debug'       => $debug,
                          'DestHost'    => $host,
                          'Community'   => $comm,
                        ) or die;

my $obj = $dev->class();

print "Using object type $obj\n";

#my $up = $dev->i_up();
#my $up_ad = $dev->i_up_admin();
#
#foreach my $port (keys %$up){
#    print "$port '$up->{$port}'\n";
#}
#
#print '-'x50,"\n";
#foreach my $port (keys %$up_ad){
#    print "$port '$up_ad->{$port}'\n";
#}

print "globals : \n";
my $globals = $dev->globals();

foreach my $global (sort keys %$globals){
    my $val = $dev->$global() || 'undef';
    print "  $global : $val \n";
}

print "other : \n";
my @other = qw/cpu mem_total cpu_5min cpu_1min model vendor os os_ver os_bin/;
foreach my $global (sort @other) {
    next if defined $globals->{$global};
    my $val = $dev->$global() || 'undef';
    print "  $global : $val \n";
}
