#!/usr/bin/perl -w

# test_fwtable.pl
#   This script is used to check forwarding table entries
#   In order to avoid getting fw_mac and fw_port, I want to
#   check to see if the entry index is the same as fw_mac
#   to speed up macsucks in netdisco.
#
use lib '/usr/local/netdisco';
use SNMP::Info;

$|=1;

my $Comm = 'public';
my @devices = (
#               ['hub850.resnet',2,'hp 4108'],
#               ['hub500.resnet',1,'bay 303'],
#               ['cmcat',1,       ,'cat. 5000'],
#               ['isp-g',2,       ,'cat. 6500'],
#               ['hub100',2,      ,'hp 4000'],
#               ['both-g',2,      ,'cat 3550'],
#               ['wavecrest-g',2, ,'2621xm'],
#               ['hub242',1,      ,'bay 304'],
               ['aironet-03.cse',2,'aironet 340','public2'],
              );

foreach my $entry (sort @devices){
    my $name = $entry->[0];
    my $ver  = $entry->[1];
    my $model= $entry->[2];
    my $comm = $entry->[3] || $Comm;

    print "\n$name $model $ver\n";
    my $dev = get_dev($name,$comm,$ver);
    unless (defined $dev){
        print "  Can't connect to $name!\n";
        next;
    }


    my $vlans = $dev->v_name() || {};

    if (scalar keys %$vlans){
        foreach my $vlan (keys %$vlans){
            my $vlan_name = $vlans->{$vlan};
            my $vlan_id = $vlan;
            $vlan_id =~  s/^\d+\.//;
            my $vlan_dev = get_dev($name,"${comm}\@${vlan_id}",$ver);
            unless (defined $vlan_dev){
                warn "  VLAN: $vlan_name ($vlan_id) failed to connect.\n";
                next;
            }
            walk_fw_table($vlan_dev);        
            undef $vlan_dev;
            print "  VLAN: $vlan_name ($vlan_id) ok.\n";
        }
    }
    walk_fw_table($dev);
}

exit;

sub get_dev {
    my $name = shift;
    my $comm = shift;
    my $ver  = shift;
    #print "$name $comm $ver\n";
    my $dev = new SNMP::Info (  Debug       => 0,
                                AutoSpecify => 1,
                                DestHost    => $name,
                                Community   => $comm,
                                Version     => $ver,
                                Retries     => 3,
                             );

    return $dev;
}

sub walk_fw_table {
    my $dev = shift;
    my $fw_table = $dev->fw_mac();

    foreach my $fwt (keys %$fw_table){
        my $index_mac = munge_index($fwt);
        my $value_mac = $fw_table->{$fwt};
        unless ($index_mac eq $value_mac){
            print " $index_mac != $value_mac\n";
        } else {
            print ".";
        } 
    }
     print "\n";

}

# munge the SNMP index value into something akin to a mac address.
sub munge_index {
    my $fwt = shift;

    my @cols = split(/\./,$fwt);
    return join(':',map {sprintf("%02x",$_)} @cols);
    
}
