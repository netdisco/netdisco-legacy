#!/usr/bin/perl
#
# Search switch/port where host (mac) was last seen
# jeroenvi - 2010-10-11
#

use warnings;
use strict;

use lib '/usr/local/netdisco';
use netdisco ':all';
use Getopt::Long;
use FindBin;             # Add this directory for netdisco.pm
use lib $FindBin::Bin;
use Data::Dumper;

use vars qw/$VERSION $DEBUG %CONFIG %args $configfile/;

$VERSION = '0.1';

# --------------------------------------------------------------
#              Command Line Flags                               
# --------------------------------------------------------------
Getopt::Long::Configure('no_ignore_case');
GetOptions(\%args,
                  'C|configfile=s',
                  'D|debug+',
                  'I|ip=s',
                  'M|mac=s',
                  'S|dumpsql',
                  'h|help',
                  'v|version|ver',

          );
$DEBUG             = $args{D} || 0;
$netdisco::SQLCARP = $args{S} || 0;

# Allow the -h or -v commands to run no matter what
defined $args{h} and &usage;
defined $args{v} and &version;

# Print Header
&header if (grep(/^([CDIMS])$/,keys %args));

# Parse Config File - Check for -C, then in current dir, then in default dir.
foreach my $c ($args{C},"$FindBin::Bin/netdisco.conf",'/usr/local/netdisco/netdisco.conf') {
    if (defined $c and -r $c){
        $configfile = $c;
        print "Using Config File : $configfile\n" if $DEBUG;
        last;
    }
}

unless (defined $configfile){
    print "No Config file found, or permission denied!\n";
    exit;
}

config($configfile);

my $searchmac;

if (defined $args{I}) {
    my $nodes = &ipsearch($args{I});
    if (scalar @$nodes == 0) {
        printf("No nodes found with IP %s.\n", $args{I});
    } elsif (scalar @$nodes > 1) {
        printf("More than 1 node found with IP %s, not checking switch ports\n", $args{I});
    } else {
        my $match = $nodes->[0];
        $searchmac = $nodes->[0]->{mac};
        printf("IP %s was last used by MAC %s.\n", $nodes->[0]->{ip}, $searchmac) if $DEBUG;
    }
}

if (defined $args{M}) {
    if (defined $searchmac) {
        printf("You specified both an IP Search and a MAC Search parameter.\n");
        printf("IP Search yielded %s, but MAC search takes precedence. Continuing with %s.\n", $searchmac, $args{M});
    }
    $searchmac = $args{M};
}

my $ports=&macsearch($searchmac);

printf("MAC,Switch,Port,LastSeen\n");
foreach my $result (@$ports) {
    print Dumper($result) if $DEBUG > 1;
    printf("%s,%s,%s,%s\n", $result->{mac}, $result->{switch}, $result->{port}, scalar localtime($result->{time_last}));
}
exit;

sub header{
    print '-'x50 . "\n";
}

sub version {
    &header;
    my $perl = defined $^V ? join('.',map {ord} split(//,$^V)) : $];
    print "Script Version     : $VERSION\n";
    print "Perl Version       : $perl\n";
    exit;
}

sub usage{
    print <<"_end_usage_";
Netdisco - Network Discovery and Management

search_node.pl [Options] Command(s)

Options:
    -C --configfile   file         Specify path to config file
    -D --debug                     DEBUG - Copious output
    -S --dumpsql                   DEBUG - Dump SQL commands

Search Commands:
    -M --mac          mac address  Search by MAC address
    -I --ip           ip address   Search by IP address

Administration:
    -v --version                Version info for Netdisco components

_end_usage_
    exit;
}

sub macsearch {
    my $node = shift;
    # Lookup what switch ports this MAC was seen at.
    my $ports = sql_rows('node',
            ['mac','switch','port','active','oui','extract(epoch from time_first) as time_first', 'extract(epoch from time_last) as time_last'],
            {'active' => 1, 'mac' => $node}
    );
    return $ports;
};

sub ipsearch {
    my $node = shift;
    my $realip;
    my $device;
    if (defined getip($node)) {
        $realip = getip($node);
        # see if this is a listed device or one of its aliases.
        $device = root_device($realip);
    } else {
        # Assume a search string
        $realip = sql_match($node);
    }
    # Find MACs associated with this IP
    my $where = { 'ip'=>$realip};
    $where->{'active'} = 1;
    my $macs = sql_rows('node_ip',
                ['mac','ip','active','extract(epoch from time_first) as time_first', 'extract(epoch from time_last) as time_last'],
                $where
    );
    return $macs;
}


