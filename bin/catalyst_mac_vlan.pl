#!/usr/local/bin/perl -w

use SNMP;
&SNMP::initMib;
&SNMP::loadModules(qw/CISCO-VTP-MIB BRIDGE-MIB CISCO-STACK-MIB/);

print<<"end_expl";
Dumps Forwarding tables on Catalyst device.
    1.  Connects to switch
    2.  gets SNMP iid to physical port mappings.
    3.  Get's list of Vlans
    4.  Connects to each VLAN and gets forwarding table 
    5.  Gets forwarding table index to iid mapping
    6.  Maps MAC -> forwarding table -> iid -> switch port
end_expl
#'  

print "Perl Version $].  SNMP : $SNMP::VERSION\n";

my $host = shift || 'commcat';
my $comm = shift || 'public';

my $snmp = new SNMP::Session(
    DestHost => $host,
    Community => $comm,
    Version => 2
    );

print "uh oh.\n" unless defined $snmp;

my %vlans = get_hash($snmp,'vtpVlanName');

# Is our index value the port index, or the cross index?
my %ports = get_hash($snmp, 'portIfIndex');
#my %ports = get_hash($snmp, 'portCrossIndex');
my %reverse_port = reverse %ports;

#die "ports : " . join(',',values %ports) . "\n";

print "vlans : " . join(',',values %vlans) . "\n";

foreach $vlan (keys %vlans) {
    ($vlan_ed = $vlan) =~ s/^.*\.//;
    $vlan_comm = $comm . '@' . $vlan_ed;
    print "VLAN: $vlans{$vlan} ($vlan_comm)\n";
    $snmp = new SNMP::Session(
        DestHost => $host,
        Community => $vlan_comm,
        Version => 2,
        Timeout => 1000000);

    die "can't connect to vlan $vlan.\n" unless defined $snmp;

    %macs = get_hash($snmp,'dot1dTpFdbPort');
    %index = get_hash($snmp,'dot1dBasePortIfIndex');

    # Let's check for broadcast and multicast
    foreach $mac (keys %macs){
        $bridge_iid = $macs{$mac};
        $snmp_iid = $index{$bridge_iid};
        $phys_port = $reverse_port{$snmp_iid};
        # Why are there mac addresses that dont map back to a port???
        $phys_port = defined $phys_port ? $phys_port : '[Not Set]';
        print "\t$mac : $bridge_iid -> $snmp_iid -> $phys_port \n";
    }
}

sub get_list {
    my $sess = shift;
    my $leaf = shift;

    my @results;

    my $var = new SNMP::Varbind([$leaf]);
    while (! $sess->{ErrorNum} ){
        $sess->getnext($var);
        last if $var->[0] ne $leaf;

        push(@results, $var->[2]);       
    }

    return @results;
}

sub get_hash {
    my $sess = shift;
    my $leaf = shift;

    my @results;

    my $var = new SNMP::Varbind([$leaf]);
    while (! $sess->{ErrorNum} ){
        $sess->getnext($var);
        last if $var->[0] ne $leaf;

        push(@results, $var->[1]);       
        push(@results, $var->[2]);       
    }

    return @results;
}

