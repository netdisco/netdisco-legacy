#!/usr/bin/perl -w

use lib qw(/usr/local/netdisco/);
use SNMP::Info;
$|=1;

print "Perl Version $].  SNMP : $SNMP::VERSION\n";

my ($host,$comm,$ver,$debug) = @ARGV;
unless (scalar(@ARGV) >=3 ){
       die << "end_usage";
$0 - spit out cdp tables
    USAGE: $0 hostname community version debug
    
    eg. $0 commcat public 2 1

end_usage
}
$debug ||= 1;

$cdp = new SNMP::Info(
        AutoSpecify => 1,
        Debug       => $debug,
		DestHost    => $host,
		Community   => $comm,
		Version     => $ver,
		) 
    or die "Couldn't create connection on $host pw:$comm.\n" unless defined $cdp;


$hascdp = $cdp->hasCDP() ? 'yes' : 'no';
print "hascdp : $hascdp\n";
print "cdpid  : " . $cdp->cdp_id() . "\n";

$ip = $cdp->c_ip();
print "neighbors : ",join(',',values %$ip),"\n";

$interfaces = $cdp->interfaces();
print "Found ", scalar(keys(%$interfaces)), " interfaces.\n";

my %funcs = %SNMP::Info::CDP::FUNCS;
my %if;
foreach $ent (keys %funcs) {
    my $val = $cdp->$ent();
    next unless defined $val;
    foreach my $key (sort keys %$val){
        $if{$key}->{$ent} = $val->{$key};
    }
}

print "\nPORT  (CDP ENTRY)\n";
my $c_if = $cdp->c_if();
foreach my $i (sort {$interfaces->{$c_if->{$a}} cmp $interfaces->{$c_if->{$b}} } keys %if){
    my $iid = $c_if->{$i};
    print "$interfaces->{$iid} ($i)\n";
    foreach my $col (keys %{$if{$i}}){
        my $val = $if{$i}->{$col};
        $val =~ s/\n/\\n/g;
        print "    $col:$val\n";
    }
}

