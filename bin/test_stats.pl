#!/usr/local/bin/perl -w

use lib qw!/usr/local/netdisco/!;
use SNMP::Info;

$| = 1;

print "Perl Version $].  SNMP : $SNMP::VERSION\n";

my $host = shift || 'commcat';
my $comm = shift || 'public';

my $cat = new SNMP::Info(
		DestHost => $host,
		Community => $comm,
        Version => 2,   
        AutoSpecify => 1,
        Debug => 1,
#        BigInt => 1
        );

die "Couldn't create connection on $host pw:$comm.\n" unless defined $cat;
print "\n$host ($comm)\n";

my $funcs = $cat->funcs();

foreach my $f (sort keys %$funcs){
    next unless $f =~ /^i_(pkts|octets)/;

    my $v = $cat->$f();

    print "$f\n";
    foreach my $a (keys %$v){
        print "  $a : $v->{$a}\n";
    }
}
