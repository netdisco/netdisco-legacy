# $Id$

=head1 NAME

netdisco.pm - Utility functions used for back and front ends

=head1 DESCRIPTION

This module provides utility functions for use with netdisco in both 
the front and backend.  Front-end specific features are limited to the
mason (.html) files, and the back-end specific features are limited to
netdisco. 

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

=cut

package netdisco;
use strict;
use Carp;
use Exporter;
use Socket;
use DBI;
use Digest::MD5;

use vars qw/%DBH $DB %CONFIG %GRAPH %GRAPH_SPEED $SENDMAIL $SQLCARP %PORT_CONTROL_REASONS $VERSION/;
@netdisco::ISA = qw/Exporter/;
@netdisco::EXPORT_OK = qw/insert_or_update getip hostname sql_do sql_begin sql_commit sql_rollback sql_disconnect has_layer
                       sql_hash sql_column sql_columns sql_rows sql_query add_node add_arp add_nbt dbh sql_match
                       all config updateconfig sort_ip sort_port sql_scalar root_device log
                       make_graph is_mac user_add user_del mail is_secure in_subnet in_subnets
                       active_subnets dump_subnet in_device get_community
                       url_secure is_private cidr mask_to_bits bits_to_mask dbh_quote sql_vacuum
                       tryuse homepath user_ldap_verify ldap_search/;

%netdisco::EXPORT_TAGS = (all => \@netdisco::EXPORT_OK);

=head1 GLOBALS

=over

=item %netdisco::DBH

Holds Database Handles, key is db name as set in config file.

=cut

=item %netdisco::DB

Index of current Database Handle.  Default C<'Pg'>;

=cut

$DB = 'Pg';

=item %netdisco::CONFIG

Holds config info from C<netdisco.conf>

=cut

=item %netdisco::GRAPH

Holds vertex information for C<make_graph()>

=cut

=item $netdisco::SENDMAIL 

Full path to sendmail executable

=cut

$SENDMAIL = '/usr/sbin/sendmail';

=item $netdisco::SQLCARP - Carps SQL!

This will C<carp()> the SQL sent off to the server for Debugging.

If running under mason, the output of C<carp()> goes to the Apache
Error Log.  From the shell it goes to STDERR.

Note that if you set this on a MASON page, the value will remain
cached across most of the current httpd proccesses.  Make sure you set it 
back to 0 via mason when you're done, unless you like watching Apache's
error_log grow.

=cut

$SQLCARP=0;

=item %PORT_CONTROL_REASONS

Reason why a port would be shutdown. These get fed into C<port_control_log>

=cut

%PORT_CONTROL_REASONS = ( 
                'address'     => ['Address Allocation Abuse',
                                  'A system which does not obtain and/or use its address in a legitimate
                                   fashion.  This includes machines that self-assign IP addresses and those
                                   that modify their MAC address.'],
                'dos'         => ['Denial Of Serivce',
                                  'Any kind of data flow, mailicious or otherwise, which is involved
                                   in a service-affecting disruption.  This includes activities such
                                   as ICMP and UDP floods, SYN attacks, and other service disruptive
                                   flows.  A system involved in a DoS attack is usually compromised.'],
                'bandwidth'   => ['Excessive BandWidth',
                                  'A user has sent/received data in excess of campus acceptable use standards.'],
                'compromised' => ['System Compromised',
                                  'The system has been compromised and poses a high risk to campus
                                   resources. If other behavior is observed, such as involvement in a DoS attack, that reason code should be used in place of this one.'],
                'copyright'   => ['Copyright Violation',
                                  "Following the takedown provision of the DMCA to limit the organization's copyright liability."],
                'exploit'     => ['Remote Exploit Possible',
                                  'A remotely exploitable vulnerability posing high risk exists on the system.'],
                'noserv'     => ['Not in service',
                                 'Port is not in service. The port may not be phsyically connected to a jack, or it may be that no one is paying for service on the associated jack.'],
                'polling'     => ['Excessive Polling of DNS/DHCP/SNMP',
                                  'Distinct from DoS attacks, excessive polling is often due to
                                   misconfigured systems or malfunctioning protocol stacks.  An example of
                                   this would be sustained, repetitive polling of the DHCP server for an
                                   address.'],
                'other'       => ['Other', 'Does not fit in any other catagory.  Make a <i>very</i> detailed <TT>Log</TT> entry.']
              );

=item $VERSION - Sync'ed with Netdisco releases

=cut

$VERSION = '1.0-RC1';

=back

=head1 Exportable Functions

=head2 General Functions

=over

=item add_arp(mac,ip)

Manipulates entries in 'node_ip' table.

Expires old entries for given IP address.

Adds new entry or time stamps matching one. 

=cut

sub add_arp {
    my ($mac,$ip) = @_;
    my $dbh = &dbh;

    # Set the active flag to false to archive all other instances
    #   of this IP address
    sql_do(qq/UPDATE node_ip SET active = 'f' WHERE ip='$ip'/);

    # Add this entry to node table. 
    my %hash = ('mac' => $mac, 'ip' => $ip);
    insert_or_update('node_ip', \%hash,
        { 'time_last' => scalar(localtime), 'active' => 1, %hash });
}

=item add_node(mac,ip,port) 

Manipulates entries in C<node> table.

Expires old entries matching given arguments.

Adds a new entry or time stamps matching old entry.

=cut

sub add_node {
    my ($mac,$ip,$port) = @_;
    my $dbh = &dbh;

    my $oui = substr($mac,0,8);
    # Set the active flag to false to archive all other instances
    #   of this mac address
    my $other = sql_do(qq/UPDATE node SET active = 'f' WHERE mac = '$mac' AND active AND NOT (switch = '$ip' AND port = '$port')/);

    # Add this entry to node table. 
    my %hash = ('switch' => $ip, 'mac' => $mac, 'port' => $port );
    my %set = ('time_last' => 'now', 'active' => 1, 'oui' => $oui);
    # if there was another node, set time_recent too.
    # NOTE: $other might be "0E0", so be careful how you test it.
    if ($other != 0) {
        $set{time_recent} = 'now';
    }
    insert_or_update('node', \%hash, { %set, %hash });
}

=item add_nbt(ip,mac,nbname,domain,server,nbuser)

Manipulates entries in 'node_nbt' table.

Expires old entries for given MAC address.

Adds new entry or time stamps matching one. 

=cut

sub add_nbt {
    my ($ip,$mac,$nbname,$domain,$server,$nbuser) = @_;
    my $dbh = &dbh;

    # Set the active flag to false to archive all other instances
    #   of this MAC address
    #sql_do(sprintf("UPDATE node_nbt SET active = 'f' WHERE mac=%s",
    #        $dbh->quote($mac)));

    # Add this entry to node_nbt table. 
    insert_or_update('node_nbt', { 'mac' => $mac },
        { 'mac' => $mac, 'ip' => $ip, 'time_last' => scalar(localtime), 
          'active' => 1, 'domain' => $domain, 'server' => $server,
          'nbname'=>$nbname, 'nbuser'=>$nbuser,
        });
}

=item bits_to_mask(bits)

Takes a CIDR style network mask in number of bits (/24) and returns the older style 
bitmask.

=cut

sub bits_to_mask {
    my $bits = shift;
    return join(".",unpack("C4",pack("N", 2**32 - (2 ** (32-$bits)))));
}

=item get_community(type,host,ip)

Get Community depending on type (ro,rw).
If C<get_community> is defined, then get the try to get the community from
shell-command. If C<get_community> is undefined or nothing
is returned from the command use C<community> or 
C<community_rw>.

The command specified in C<get_community> must return in stdout a string like

    community=<list of readonly-communities>
    setCommunity=<list of write-communities>

Returns Community-List as Array reference

Options:
    type => 'ro'|'rw' for the type of community
    host => name of the device
    ip   => device ip-address

=cut

sub get_community($$;$) {
    my $type = lc(shift);
    my $host = shift;
    my $ip = shift || $host;
 
    my $cmd   = $CONFIG{get_community};
    my $rcom  = $CONFIG{community};
    my $rwcom = $CONFIG{community_rw};
 
    if (defined $cmd && length($cmd)) {
        my @com;
        # replace variables
        $cmd =~ s/\%HOST\%?/$host/egi;
        $cmd =~ s/\%IP\%?/$ip/egi;
        my $return = `$cmd`;
        my @lines = split (/\n/,$return);
        foreach (@lines) {
            if (/^community\s*=\s*(.*)\s*$/i) {
                if (length($1)) {
                    @com = split(/\s*,\s*/,$1);
                    $rcom = \@com;
                } else {
                    $rcom = undef;
                }
            } elsif (/^setCommunity\s*=\s*(.*)\s*$/i) {
                if (length($1)) {
                    @com = split(/\s*,\s*/,$1);
                    $rwcom = \@com;
                } else {
                    $rwcom = undef;
                }
            }
        }
    }
    return  ($type eq 'rw' ? $rwcom : $rcom);
}

=item  config() 

Reads the config file and fills the C<%CONFIG> hash.

=cut

sub config {
    my $file = shift;
    my %args = @_;

    # all default to 0
    my @booleans = qw/compresslogs ignore_private_nets reverse_sysname daemon_bg
                      port_info secure_server graph_clusters graph_splines portctl_uplinks
                      portctl_nophones portctl_vlans macsuck_all_vlans macsuck_bleed
                      bulkwalk_off vlanctl apache_auth nonincreasing store_modules
                      vacuum_no store_wireless_client/;

    # these will make array refs of their comma separated lists
    my @array_refs = qw/community community_rw mibdirs bulkwalk_no
                        macsuck_no arpnip_no discover_no ignore_interfaces
                        macsuck_only arpnip_only discover_only
                        snmpforce_v1 snmpforce_v2 snmpforce_v3 db_tables
                        v3_users v3_users_rw
                        ldap_server /;

    # these will make a reference to a hash:
    #      keys :comma separated list entries value : number > 0
    my @hash_refs  = qw/portcontrol admin web_console_vendors
                       web_console_models macsuck_no_vlan
                       ldap_opts ldap_tls_opts
                      /;

    # Multiple arrays
    my @array_refs_mult = qw/node_map/;

    # Reference to a hash; each line is an entry in the hash,
    #  with format key:value
    my @hash_refs_mult = qw/v3_user/;

    # Add custom types from caller outside netdisco
    foreach my $type qw(booleans array_refs hash_refs array_refs_mult hash_refs_mult) {
        eval "push(\@$type, \@{\$args{config}{\$type}});";
    }

    open(CONF, "<$file") or die "Can't open Config File $file. $!\n";
    my @configs=(<CONF>);    
    close(CONF);

    # Clear out config values where can build up
    foreach my $a (sort @array_refs_mult) {
        $CONFIG{$a} = [];
    }
    foreach my $a (@hash_refs_mult) {
        $CONFIG{$a} = {};
    }

    while(my $config = shift @configs){
        chomp $config;

        # Check for wrap (\ at end of line)
        my $cur_line = $config;
        while ($cur_line =~ /\\\s*$/){
            # Remove tailing \
            $config =~ s/\\\s*$//;
    
            # Grab next line
            my $next_line = shift(@configs);
            chomp($next_line);

            # Check for trailing \ on newline
            if ($next_line =~ /\\\s*$/) { 
                # If comments in line too, add the \ back in
                if ($next_line =~ s/(?<!\\)#.*//){
                    $next_line .= '\\'; 
                }
            # Otherwise just remove the comments
            } else {
                $next_line =~ s/(?<!\\)#.*//;
            }
            # Handle escaped pound signs
            $next_line =~ s/\\#/#/g;
            
            # Trim out leading whitespace
            $next_line =~ s/^\s*/ /;

            # concat next line to current.
            $config .= $next_line; 

            # could have lots of \'d lines in a row
            $cur_line = $next_line;
        }

        # Take out Comments - Handle escaped pound signs
        $config =~ s/(?<!\\)#.*//;
        $config =~ s/\\#/#/g;
        # Trim leading and trailing white space
        $config =~ s/^\s*//;
        $config =~ s/\s*$//;
        # Ignore Blank Lines
        next unless (length $config);

        # Fill the %CONFIG hash
        my $var = undef;  my $value = undef;
        if ($config =~ /^([a-zA-Z_\-0-9]+)\s*=\s*(.*)$/) {
            $var = $1;  $value = $2;
        } 
        unless(defined $var and defined $value){
            print STDERR "Bad Config Line : $config\n";
            next;
        }

        # Config Variable Expansion ($home will become $CONFIG{home})
        #       ignores \$expression
        while ($value =~ m/(?<!\\)\$([a-zA-Z_-]+)/g){
            my $configvar = $1; my $configval = $CONFIG{$configvar};
            $value =~ s/(?<!\\)\$$configvar/$configval/g if defined $configval;
        }

        # change \$ to $
        $value =~ s/\\\$/\$/g;
            
        # Hacks
        
        # Booleans
        if (grep /^\Q$var\E$/,@booleans) {
            if ( $value =~ /^(1|t|y|yes|true|si|oui)$/i ) {
                $value = 1;
            } else {
                $value = 0;
            } 
        }

        # Comma separated lists -> array ref
        if (grep /^\Q$var\E$/,@array_refs) {
            my @com = split(/\s*(?<!\\),\s*/,$value);
            foreach (@com){
                $_ =~ s!\\,!,!g;
            }
            $value = \@com;
        }


        # Multiple array refs
        if (grep /^\Q$var\E$/,@array_refs_mult) {
            my $oldvalue = $CONFIG{$var};
            push (@$oldvalue, $value);
            $value = $oldvalue;
        }

        # Multiple hash refs
        if (grep /^\Q$var\E$/,@hash_refs_mult) {
            my ($key, $val) = split(/\s*:\s*/, $value, 2);
            $value = $CONFIG{$var};
            $value->{$key} = $val;
        }

        # Comma separated lists that map to defined hash keys.
        if (grep /^\Q$var\E$/,@hash_refs) {
            my %seen;
            foreach my $key (split(/\s*(?<!\\),\s*/,$value)){
                $key =~ s/^\s+//;
                $key =~ s/\s+$//;
                $key =~ s!\\,!,!g;
                $seen{$key}++;
            }            
            $value = \%seen;
        }
    
        # Database Hash values 
        if ($var =~ /^db_([a-zA-z]+)_opts$/){
            my %opts;
            foreach my $pair (split(/\s*(?<!\\),\s*/,$value)) {
                $pair =~ s!\\,!,!g;
                my ($hash_key,$hash_value) = split(/\s*=>\s*/,$pair);
                $opts{$hash_key}=$hash_value;
            }
            $value = \%opts;
        }

        $CONFIG{$var}=$value;

    }

    $CONFIG{'@file'} = $file;
    $CONFIG{'@mtime'} = -M $file;

    *::CONFIG = \%CONFIG;
    return \%CONFIG;
}

=item  updateconfig() 

Checks the modification time of the configuration file and
re-reads it if needed.  (Note: for now, defaults are not
reset - i.e., if there was an item in the config file before,
and it is missing when we reread it, it keeps its old value
and doesn't get set to the default.)

Uses eval to run config, so that we can keep running with the old
config if there's a problem with the config file.

=cut

sub updateconfig {
        my $needupdate = 0;

        if (defined($CONFIG{'@file'}) && defined($CONFIG{'@mtime'})) {
                if (-M $CONFIG{'@file'} < $CONFIG{'@mtime'}) {
                        $needupdate = 1;
                }
        }
        if ($needupdate) {
                eval { config($CONFIG{'@file'}); };
                if ($@) {
                        carp($@);
                }
        }
        $needupdate;
}

=item has_layer(bit string,layer) 

Takes ascii encoded string of eight bits, and checks for the specific
layer being true.  Most significant bit first.

    has_layer(00000100,3) = true

=cut

sub has_layer {
    my ($layers,$check_for) = @_;
    return  substr($layers,8-$check_for, 1);
}


=item hostname(ip) 

Returns the DNS server entry for the given ip or hostname.

=cut

sub hostname {
    my $ip = shift;

    my @host = gethostbyaddr(inet_aton($ip), AF_INET);

    return $host[0];
}


=item getip(host) 

Returns the IP Address of a given IP or hostname. If the 
given argument appears to be in dotted octet notation, it
does no DNS hits and just returns it.

It also just returns an IP address with a subnet mask.
Subnet masks are not permitted on host names.

=cut

sub getip {
    my $hostname = shift;

    my $ip;

    if ($hostname =~ /^\d+\.\d+\.\d+\.\d+(?:\/\d+)?$/) {
        $ip = $hostname;
    } else {
        my $testhost = inet_aton($hostname) || inet_aton($hostname . ($CONFIG{domain} || ''));
        return undef unless (defined $testhost and length $testhost);
        $ip = inet_ntoa($testhost);
    }
    return $ip;
}

=item in_device(device,to_match)

First argument can either be:

    1. plain text IP or hostname
    2. A row from the device table as returned from sql_hash

Second argument is an array ref as returned from config, eg. C<bulkwalk_no>.

=cut

sub in_device {
    my $device = shift;
    my $to_match = shift;

    return 0 unless defined $to_match;
    return 0 unless defined $device;

    my ($ip,$terms);


    # First Argument:
    # Passed a sql_hash from the device table
    if (ref($device) eq 'HASH'){
        $ip     = $device->{ip};
        $terms  = $device;
    # Passed as simple hostname/IP
    } else {
        $ip     = getip($device);
        $terms  = {};
    }

    # Second Argument:
    foreach my $term (@$to_match){
        $term =~ s/^\s*//;
        $term =~ s/\s*$//;
        # Check for device types
        if ($term =~ /(.*)\s*:\s*(.*)/){
            my $attrib = lc($1); my $match = $2;

            return 1 if $terms->{$attrib} && $terms->{$attrib} =~ /^$match$/;
            
        # Blanket wildcard
        } elsif ($term eq '*') {
            return 1; 
        # Consider this a subnet / host
        } else {
            #print "checking $term against $ip\n";
            return 1 if in_subnet(getip($term),$ip);
        }
    }

    return 0;
}

=item in_subnet(subnet,ip)

Returns Boolean.  Checks to see if IP address is in subnet.  Subnet
is defined as single IP address, or CIDR block.  Partial CIDR format
(192.168/16) is NOT supported.

 in_subnet('192.168.0.0/24','192.168.0.3') = 1;
 in_subnet('192.168.0.3','192.168.0.3') = 1;


=cut

sub in_subnet{
    my ($subnet,$ip) = @_;

    unless (defined $subnet and defined $ip){
        return undef;        
    }

    # No / just see if they're equal
    if ($subnet !~ m!/!) {
        return ($subnet eq $ip) ? 1 : 0;
    }

    # Parse Subnet
    my ($root,$bits);
    if ($subnet =~ /^([\d\.]+)\/(\d+)$/){
       $root = $1;  $bits = $2; 
    } else { return undef; }

    my $root_bin = unpack("N",pack("C4",split(/\./,$root)));
    my $mask = 2**32 - (2 ** (32 - $bits));

    # Parse IP
    my $ip_bin = unpack("N",pack("C4",split(/\./,$ip)));
    
    # Root matches and Mask Matches
    return (    ($ip_bin & $mask) == $root_bin
            and ($ip_bin & ~ $mask)
           ) ? 1 : 0;
}

=item in_subnets(ip,config_directive)

Returns Boolean.  Checks a given IP address against all the IPs and subnet
blocks listed for a config file directive.

 print in_subnets('192.168.0.1','macsuck_no');

=cut

sub in_subnets {
    my ($ip,$config) = @_;

    return 0 unless defined $CONFIG{$config};
    return 0 unless defined $ip;

    foreach my $net (keys %{$CONFIG{$config}}) {
        return 1 if in_subnet($net,$ip);
    }

    return 0;
}

=item active_subnets()

Returns array ref containing all rows from the subnets table that
have a node or device in them.

=cut

sub active_subnets {
    my $subnets = sql_rows('subnets',['net'],undef,undef,'order by net');
    my $active = [];

    foreach my $row (@$subnets) {
        my $net = $row->{net};
        my $found = 0;
        $found ||= sql_scalar('node_ip',['1 as yup'],{'ip' => \\"<< '$net'"});
        $found ||= sql_scalar('device',['1 as yup'],{'ip' => \\"<< '$net'"});
        $found ||= sql_scalar('device_ip',['1 as yup'],{'alias' => \\"<< '$net'"});
        push(@$active, $net) if $found;
    }
    return $active;
}

=item dump_subnet(cidr style subnet)

Serves you all the possible IP addresses in a subnet.

Returns reference to hash.  Keys are IP addresses
in dotted decimal that are in the subnet. 

Gateway and Broadcast (.0 .255) addresses are not included.

  $hash_ref = dump_subnet('192.168.0.0/24');
  scalar keys %$hash_ref == 254;

Also accepted :

  dump_subnet('14.0/16');
  dump_subnet('4/24');

=cut

sub dump_subnet {
    my $subnet = shift;

    # Parse Subnet
    my ($root,$bits);
    if ($subnet =~ /^([\d\.]+)\/(\d+)$/){
       $root = $1;  $bits = $2; 
    } else { return;}
    
    # parse partial subnets 
    my @roots = split(/\./,$root);
    for (my $i=0; scalar(@roots) < 4; $i++){
        push (@roots,0);
    }
    my $root_bin = unpack("N",pack("C4",@roots));
    my $mask = 2**32 - (2 ** (32 - $bits));
    
    my $addrs = {};
    for (my $ip_bin=$root_bin+1;$ip_bin < 2**32; $ip_bin++){
        last unless (($ip_bin & $mask) == $root_bin and ($ip_bin & ~ $mask));
        my $ip = inet_ntoa(pack('N', $ip_bin));
        next if $ip =~ m/\.(255|0)$/;
        $addrs->{$ip}++;
    }

    return $addrs;
}

=item is_mac(mac) 

Returns Boolean.  Checks if argument appears to be a mac address.

Checks for types :

    08002b:010203
    08002b-010203
    0800.2b01.0203
    08-00-2b-01-02-03
    08:00:2b:01:02:03


=cut

sub is_mac{
    my $mac = shift;
    my $hex = "[0-9a-fA-F]";
    
    #'08002b:010203', '08002b-010203'
    return 1 if ($mac =~ /^${hex}{6}[:-]{1}${hex}{6}$/);
    #'0800.2b01.0203'
    return 1 if ($mac =~ /^${hex}{4}\.${hex}{4}\.${hex}{4}$/);
    #'0800-2b01-0203' c/o http://sites.google.com/site/jrbinks/code/netdisco/mac-patches
    return 1 if ($mac =~ /^${hex}{4}-${hex}{4}-${hex}{4}$/);
    # '08-00-2b-01-02-03','08:00:2b:01:02:03'
    return 1 if ($mac =~ /^${hex}{2}-${hex}{2}-${hex}{2}-${hex}{2}-${hex}{2}-${hex}{2}$/);
    return 1 if ($mac =~ /^${hex}{2}:${hex}{2}:${hex}{2}:${hex}{2}:${hex}{2}:${hex}{2}$/);
    return 0;
}

=item log(class,text)

Inserts an entry in the C<log> table.

    log('error',"this is an error");

=cut

sub log {
    my ($class,$entry,$file) = @_;

    insert_or_update('log',undef,{'class' => $class, 'entry' => $entry, 'logfile' => $file});
    
}

=item mail(to,subject,body)

Sends an E-Mail as Netdisco

=cut

sub mail {
    my ($to,$subject,$body) = @_;
    my $domain = $CONFIG{domain} || 'localhost';
    $domain =~ s/^\.//;
    open (SENDMAIL, "| $SENDMAIL -t") or die "Can't open sendmail at $SENDMAIL.\n";
    print SENDMAIL "To: $to\n";
    print SENDMAIL "From: Netdisco <netdisco\@$domain>\n";
    print SENDMAIL "Subject: $subject\n\n";
    print SENDMAIL $body;
    close (SENDMAIL) or die "Can't send letter. $!\n";
}

=item is_private(ip)

Returns true if a given IP address is in the RFC1918 private
address range.

=cut

sub is_private {
    my ($ip) = @_;
    my $ignore = 0;

    # Class A Private
    $ignore++ if $ip =~ /^10\./;
    # Class B Private
    $ignore++ if $ip =~ /^172\.(\d+)\./ && ($1 >= 16 && $1 <= 31);
    # Class C private
    $ignore++ if $ip =~ /^192\.168\./;

    return $ignore;
}

=item cidr(ip, mask)

Takes an IP address and netmask and returns the CIDR format
subnet.

=cut

sub cidr {
    my ($ip, $mask) = @_;
    my $bits = mask_to_bits($mask);

    return undef if (!defined($ip) || !defined($mask));

    my $nip = unpack("N", pack("C*", split(/\./, $ip)));
    my $nmask = unpack("N", pack("C*", split(/\./, $mask)));
    my $netaddr = join(".", unpack("C*", pack("N", $nip & $nmask)));
    return "$netaddr/$bits";
}

=item mask_to_bits(mask)

Takes a netmask and returns the CIDR integer number of bits.

    mask_to_bits('255.255.0.0') = 16

=cut

sub mask_to_bits{
    my $mask = shift;
    
    my $sum = undef;
    for my $oct (split(/\./,$mask)){
        return undef if ($oct > 255 or $oct < 0 );
        for my $bits (split(//,unpack("B*",pack("C",$oct)))) {
            $sum += $bits;
        }
    }

    return $sum;
}

=item is_secure

To be run under mason only.

Returns true if the server want's to be secure and is, or true if the server doesn't want to be secure.

Returns false if the server is not secure but wants to be.

=cut

sub is_secure {

    my $secure = $CONFIG{secure_server};
    return 1 unless defined $secure;
    return 1 if $secure !~ /^(1|y|t)/i;

    # secure_server is set.
    my $ar = $::r || $HTML::Mason::Commands::r;
    unless (defined $ar and $ar->can('subprocess_env')){
        carp "netdisco::is_secure() - Can't find Apache \$r\n";
        return;
    }

    if (defined $ar->subprocess_env('https') and $ar->subprocess_env('https') eq 'on') {
        return 1;
    }

    return 0;
}

=item url_secure(url)

=cut

sub url_secure {
    my $path = shift;
    
    return unless defined $path;

    my $ar = $::r || $HTML::Mason::Commands::r;
    unless (defined $ar and $ar->can('hostname')){
        carp "netdisco::url_secure() - Can't find Apache \$r\n";
        return;
    }

    my $webpath = $CONFIG{webpath};
    my $server  = $ar->hostname;

    # Check for the easy case
    if ($path =~ m!^http(s)?://!){
        $path =~ s!^http://!https://!;
        return $path;
    }

    # Check for single file
    elsif ($path !~ m!^$webpath!){
        $path =~ s!^/+!!;
        $path = "https://${server}${webpath}/$path";
    } 

    # Check for full path 
    elsif ($path =~ m!^$webpath!){
        $path = "https://${server}${path}"; 
    }
    
    return $path;
}

=item sort_ip() 

Used by C<sort {}> calls to sort by IP octet.

If passed two hashes, will sort on the key C<ip> or C<remote_ip>.

=cut

sub sort_ip {
    my $aval = shift || $::a || $HTML::Mason::Commands::a || $a;
    my $bval = shift || $::b || $HTML::Mason::Commands::b || $b;
    $aval = $aval->{ip} || $aval->{remote_ip} if ref($aval) eq 'HASH';
    $bval = $bval->{ip} || $bval->{remote_ip} if ref($bval) eq 'HASH';
    my ($a1,$a2,$a3,$a4) = split(/\./,$aval);
    my ($b1,$b2,$b3,$b4) = split(/\./,$bval);
    
    return 1 if ($a1 > $b1);
    return -1 if ($a1 < $b1);
    return 1 if ($a2 > $b2);
    return -1 if ($a2 < $b2);
    return 1 if ($a3 > $b3);
    return -1 if ($a3 < $b3);
    return 1 if ($a4 > $b4);
    return -1 if ($a4 < $b4);
    return 0;
}

=item sort_port()

Used by C<sort()> - Sort port names with the following formatting types :

    A5
    5
    FastEthernet0/1
    FastEthernet0/1-atm
    5.5
    Port:3

Works on hashes if a key named port exists. 

Cheers to Bradley Baetz (bbaetz) for improvements in this sub.

=cut

sub sort_port {
    my $aval = shift || $::a || $HTML::Mason::Commands::a || $a || '';
    my $bval = shift || $::b || $HTML::Mason::Commands::b || $b || '';
    $aval = $aval->{port} if ref($aval) eq 'HASH';
    $bval = $bval->{port} if ref($bval) eq 'HASH';

    my $numbers        = qr{^(\d+)$};
    my $numeric        = qr{^([\d\.]+)$};
    my $dotted_numeric = qr{^(\d+)\.(\d+)$};
    my $letter_number  = qr{^([a-zA-Z]+)(\d+)$};
    my $wordcharword   = qr{^([^:\/.]+)[\ :\/\.]+([^:\/.]+)(\d+)?$}; #port-channel45
    my $ciscofast      = qr{^
                            # Word Number (Gigabit0)
                            (\D+)(\d+)
                            # Groups of symbol float (/5.5/5.5/5.5)
                            (?:                     # group, don't capture to $1 
                              # /5.5
                              [:\/\.]+([\d\.]+)     # capture float
                            )+
                              # Optional dash (-Bearer Channel)
                            (-.*)?
                            $}x;

    my @a = (); my @b = ();
    
    if ($aval =~ $dotted_numeric) {
        @a = ($1,$2);
    } elsif ($aval =~ $letter_number) {
        @a = ($1,$2);
    } elsif ($aval =~ $numbers) {
        @a = ($1);
    } elsif ($aval =~ $ciscofast) {
        @a = ($1,$2,$3,$4,$5,$6);
    } elsif ($aval =~ $wordcharword) {
        @a = ($1,$2,$3);
    } else { 
        @a = ($aval);
    }

    if ($bval =~ $dotted_numeric) {
        @b = ($1,$2);
    } elsif ($bval =~ $letter_number) {
        @b = ($1,$2);
    } elsif ($bval =~ $numbers) {
        @b = ($1);
    } elsif ($bval =~ $ciscofast) {
        @b = ($1,$2,$3,$4,$5,$6);
    } elsif ($bval =~ $wordcharword) {
        @b = ($1,$2,$3);
    } else { 
        @b = ($bval);
    }

    # Equal until proven otherwise
    my $val = 0;
    while (scalar(@a) or scalar(@b)){
        # carried around from the last find.
        last if $val != 0;

        my $a1 = shift @a;
        my $b1 = shift @b;

        # A has more components - loses
        unless (defined $b1){
            $val = 1;
            last;
        }

        # A has less components - wins
        unless (defined $a1) {
            $val = -1;
            last;
        }

        if ($a1 =~ $numeric and $b1 =~ $numeric){
            $val = $a1 <=> $b1;
        } elsif ($a1 ne $b1) {
            $val = $a1 cmp $b1;
        }
    }
    
    return $val;
}

=item make_graph()

Returns C<Graph::Undirected> object that represents the discovered
network.

Graph is made by loading all the C<device_port> entries
that have a neighbor, using them as edges. Then each device seen in those
entries is added as a vertex.  

Nodes without topology information are not included.

=cut

sub make_graph {
    tryuse('Graph', ver => 0.50, die => 1);
    my $G = new Graph::Undirected;
    print "my \$G = new Graph::Undirected;\n" if $::DEBUG;

    my $devs_raw = sql_rows('device',['ip','dns','location']);
    my $aliases = sql_column('device_ip',['alias','ip']);
    my $links = sql_rows('device_port',['ip','remote_ip','speed','remote_type'],{'remote_ip' => 'IS NOT NULL'});

    my %devs;
    my %locs;
    foreach my $dev (@$devs_raw){
        my $ip = $dev->{ip};
        my $dns = $dev->{dns};
        $devs{$ip} = $dns;
        $locs{$ip} = $dev->{location};
    }

    # Check for no topology info
    unless (scalar @$links){
        print "make_graph() - No Topology information.\n" if $::DEBUG; 
        return undef;
    }

    my %link_seen;
    my %linkmap;
    foreach my $link (@$links){
        my $source = $link->{ip};
        my $dest   = $link->{remote_ip};
        my $speed  = $link->{speed};
        my $type   = $link->{remote_type};

        # Check for Aliases 
        if (defined $aliases->{$dest} ){
            # Set to root device
            $dest = $aliases->{$dest};
        }

        # Remove loopback - After alias check (bbaetz)
        if ($source eq $dest) {
            print "Loopback on $source\n" if $::DEBUG;
            next;
        }
    
        # Skip IP Phones
        if (defined $type and $type =~ /ip.phone/i){
            print "Skipping IP Phone. $source -> $dest ($type)\n" if $::DEBUG;
            next;
        }
        next if exists $link_seen{$source}->{$dest};

        push(@{$linkmap{$source}},$dest);
    
        # take care of reverse too
        $link_seen{$source}->{$dest}++;
        $link_seen{$dest}->{$source}++;
        $GRAPH_SPEED{$source}->{$dest}->{speed}=$speed;
        $GRAPH_SPEED{$dest}->{$source}->{speed}=$speed;
    } 

    foreach my $link (keys %linkmap){
        foreach my $dest (@{$linkmap{$link}}) {

            # Check for source existance :
            unless( defined $GRAPH{$link} ) {
                my $is_dev = exists $devs{$link};
                my $dns = $is_dev ?
                          $devs{$link} :
                          hostname($link);

                # Default to IP if no dns
                $dns = defined $dns ? $dns : "($link)";

                $G->add_vertex($link);
                print "\$G->add_vertex('$link');\n" if $::DEBUG;
                $GRAPH{$link}->{dns} = $dns;
                $GRAPH{$link}->{isdev} = $is_dev;
                $GRAPH{$link}->{seen}++;
                $GRAPH{$link}->{location} = $locs{$link};
            }

            # Check for dest existance :
            unless( defined $GRAPH{$dest} ) {
                my $is_dev = exists $devs{$dest};
                my $dns = $is_dev ?
                          $devs{$dest} :
                          hostname($dest);

                # Default to IP if no dns
                $dns = defined $dns ? $dns : "($dest)";

                $G->add_vertex($dest);
                print "\$G->add_vertex('$dest');\n" if $::DEBUG;
                $GRAPH{$dest}->{dns} = $dns;
                $GRAPH{$dest}->{isdev} = $is_dev;
                $GRAPH{$dest}->{seen}++;
                $GRAPH{$dest}->{location} = $locs{$dest};
            }

            $G->add_edge($link,$dest);
            print "\$G->add_edge('$link','$dest');\n" if $::DEBUG;
        }
    }
    return $G;
}

=item root_device(ip)

If the given IP Address matches a device IP, returns it.

If the given IP Address matches an alias of a device, returns
the IP of the device the alias belongs to.

=cut

sub root_device {
    my $ip = shift;
    my $dbh = &dbh;

    $ip = $dbh->quote($ip);
   
    my $sql = "SELECT ip FROM device WHERE ip = $ip UNION";
       $sql.= " (SELECT ip FROM device_ip WHERE alias = $ip);";

    my $row = $dbh->selectrow_hashref($sql);
    return undef unless (defined $row and defined $row->{ip});
    return $row->{ip};
}

=back

=head2 User Functions

=over

=item user_add(user,%args)

Adds or changes a user account.

C<%args> can have key values of { pw, admin, port, ldap, full_name, note }

Returns error message if problem.

=cut

sub user_add {
    my ($user, %args) = @_;

    unless (defined($user) and scalar(keys(%args))){
        return "Not enough arguments passed.";
    }

    $user = lc($user);

    my %db_args;
    foreach my $arg (keys %args){
        my $val = $args{$arg};
        if ($arg eq 'pw'){
            $db_args{password} = Digest::MD5::md5_hex($val);
        }
        
        if ($arg eq 'admin') {
            $db_args{admin} = ($val =~ /^(1|true|yes|y)$/i) ? 1 : 0;
        }

        if ($arg eq 'ldap') {
            $db_args{ldap} = ($val =~ /^(1|true|yes|y)$/i) ? 1 : 0;
        }

        if ($arg eq 'port') {
            $db_args{port_control} = ($val =~ /^(1|true|yes|y)$/i) ? 1 : 0;
        }
        
        if ($arg eq 'note') {
           $db_args{note} = $val;
        }

        if ($arg eq 'fullname') {
           $db_args{fullname} = $val;
        }

    }

    return insert_or_update('users',{'username'=>$user},{'username'=>$user,%db_args});
}

=item user_del(user)

Deletes a user from netdisco.

Returns result from C<DBI-E<gt>do()> 

Integer for number of rows deleted, or undef if error.

=cut

sub user_del{
    my $user = shift;
    my $dbh = &dbh;
    $user = $dbh->quote($user);
    return sql_do(qq/DELETE from users where username=$user/);
}

=item user_ldap_verify(user,password)

Test a user from netdisco.

Returns 1 if user and password are OK, or undef if error.

=cut

sub user_ldap_verify{
    tryuse('Net::LDAP', die => 1);
    my ($user, $pass) = @_;

    return undef unless defined($user);

    my $ldapuser = $CONFIG{ldap_user_string};
    $ldapuser =~ s/\%USER\%?/$user/egi;

    # If we can bind as anonymous or proxy user
    # search for user's distinguished name
    if ( $CONFIG{ldap_proxy_user} ) {
        my $user   = $CONFIG{ldap_proxy_user};
        my $pass   = $CONFIG{ldap_proxy_pass};
        my $attrs  = ['distinguishedName'];
        my $result = ldap_search ($ldapuser, $attrs, $user, $pass);
        $ldapuser  = $result->[0] if ($result->[0]);
    }
    # If we can't search and aren't using AD and then construct DN by
    # appending base
    elsif ( $ldapuser =~ /=/ ) {
        $ldapuser = "$ldapuser,$CONFIG{ldap_base}";
    }
    
    foreach my $server (@{$CONFIG{ldap_server}}) {
        my $opts = $CONFIG{ldap_opts} || {};
        my $ldap = Net::LDAP->new( $server, %$opts ) or next;

        my $msg ;

        if ( $CONFIG{ldap_tls_opts} ) {
            $msg  = $ldap->start_tls( %{$CONFIG{ldap_tls_opts}} );
        }
       
        $msg = $ldap->bind( $ldapuser, password => $pass );

        $ldap->unbind(); # take down session

        return 1 unless $msg->code();
    }
    return undef;
}

=item ldap_search(filter,attrs,user,pass)

Perform an LDAP search from the configured ldap_base with the specified filter.

Uses an anonymous bind if the user is 'anonymous' or undefined.

Returns reference to an array of Net::LDAP::Entry objects which match the
search filter.  Each entry will contain the accessible attributes as defined
in attrs array reference.  If attrs is undefined, then the server will return
the attributes that are specified as accessible by default given the bind
credentials.

=cut

sub ldap_search {
    tryuse('Net::LDAP', die => 1);
    my ($filter, $attrs, $user, $pass) = @_;

    return undef unless defined($filter);
    return undef if (defined $attrs and ref($attrs) ne 'ARRAY');

    foreach my $server (@{$CONFIG{ldap_server}}) {
        my $opts = $CONFIG{ldap_opts} || {};
        my $ldap = Net::LDAP->new( $server, %$opts ) or next;

        my $msg;

        if ( $CONFIG{ldap_tls_opts} ) {
            $msg  = $ldap->start_tls( %{$CONFIG{ldap_tls_opts}} );
        }
        
        if ( $user and $user ne 'anonymous' ) {
            $msg = $ldap->bind( $user, password => $pass);
        }
        else {
            $msg = $ldap->bind();
        }

        $msg = $ldap->search(   
                                base=> $CONFIG{ldap_base},
                                filter=>"($filter)",
                                attrs=> $attrs );

        $ldap->unbind(); # take down session
        
        my $entries = [ $msg->entries ];

        return $entries unless $msg->code();
    }
    return undef;
}

=back

=head2 SQL Functions

=over

=item dbh()

Creates and returns a database handle. Creates once, then 
returns the cached copy.  

Select database handle in use by localizing C<$netdisco::DB>

=cut

sub _make_connection {
    my $connect = $CONFIG{"db_$DB"}        or die "dbh() - db_$DB not found in config info.\n";
    my $user    = $CONFIG{"db_${DB}_user"} or die "dbh() - db_${DB}_user not found in config info.\n";
    my $pw      = $CONFIG{"db_${DB}_pw"}   or die "dbh() - db_${DB}_pw not found in config info.\n";
    my $options = $CONFIG{"db_${DB}_opts"} || {};
    my $env     = $CONFIG{"db_${DB}_env"} || '';
    # Multiple environmental variables separated by commas.
    foreach my $e (split(/\s*(?<!\\),\s*/,$env) ) {
        $e =~ s!\\,!,!g;
        my ($key,$val) = split(/\s*=>\s*/,$e);
        next unless (defined $key and defined $val and $key and $val);
        #warn "Setting ENV{$key} to $val\n";
        $ENV{$key}=$val;
    }

    my $h = DBI->connect($connect,$user,$pw,$options)
        or die "Can't connect to DB. $DBI::errstr\n";
    return $h;
}

sub dbh {
    unless ($INC{'Apache/DBI.pm'} && $ENV{MOD_PERL}) {
        unless ($DBH{$DB} && $DBH{$DB}->ping) {
            $DBH{$DB} = &_make_connection;
        }
        return $DBH{$DB};
    }
    return &_make_connection;
}


=item dbh_quote($text)

Runs DBI::dbh->quote() on the text and returns it.

=cut

sub dbh_quote {
    my $text = shift;

    my $dbh = &dbh;

    return $dbh->quote($text);
}

=item hash_diff($hashref_orig,$hashref_new)

Sees if items to change in second hash are different or new compared to first.

=cut

sub hash_diff {
    my ($orig,$change) = @_;

    foreach my $change_key (keys %$change) {
        # Different if key doesnt exist in the orig
        return 1 unless (defined $orig->{$change_key} and length($orig->{$change_key}));
        # If the two are different
        return 1 if(defined $orig->{$change_key} and ! defined $change->{$change_key});
        return 1 if($orig->{$change_key} ne $change->{$change_key});
    }
    return 0;
}

=item insert_or_update(table, {matching}, {values} )

Checks for Existing entry in table using C<\%matching> and either
updates or inserts into table with C<\%values> accodringly.

    insert_or_update('device', { 'ip'=>'127.0.0.1' },
                     { 'ip' => '127.0.0.1', dns => 'dog' }
                    ); 

First time called it will insert the new entry

Second time called it will modify the entry with the values.

Supports

    * Auto Quoting of Values

Returns undef if problem.

On inserts in PostgreSQL, returns the OID of the row inserted.

Or returns value from C<DBD::St::execute()>

=cut

sub insert_or_update {
    my ($table, $indexes, $values) = @_;

    my $dbh = &dbh;    

    my $sql;
    # Check for update
    if (scalar keys %$indexes){
        # Get Existing
        my @where;
        foreach my $index (keys %$indexes){
            my $value = $indexes->{$index};
            $value = $dbh->quote($value);
            $value =~ s/\0//g;
            push(@where, "$index = $value ");
        }

        my $wherestr = join(' AND ',@where);

        $sql = qq/SELECT * FROM $table WHERE $wherestr FOR UPDATE/;

        carp("[$$] $sql") if $SQLCARP;
        my $row = $dbh->selectrow_hashref($sql);
        carp "insert_or_update($sql) ". $dbh->errstr . "\n" if $dbh->err;

        my $diff = &hash_diff($row,$values);

        # Update
        if (defined $row and $diff) {
            $sql = sprintf("UPDATE $table SET %s WHERE $wherestr",
                join(',',map { sprintf("$_=%s",$dbh->quote($values->{$_})) } keys %$values));

            # Certain devices were null padding and postgres barfs on nulls in text fields.
            $sql =~ s/\0//g;
            carp("[$$] $sql") if $SQLCARP;

            $dbh->do($sql); 
            if ($dbh->err) { 
                carp "insert_or_update($sql) ". $dbh->errstr . "\n";
                return $dbh->errstr; 

            }
            return;
        } elsif (defined $row and !$diff) { 
            return;
        }
    }

    # Insert
    $sql =  sprintf("INSERT into $table (%s) VALUES (%s);",
            join(',',keys(%$values)), 
            join(',',map {$dbh->quote($_)} values(%$values)));

    # Certain devices were null padding and postgres barfs on nulls in text fields.
    $sql =~ s/\0//g;
    carp("[$$] $sql") if $SQLCARP;

    my $sth = $dbh->prepare($sql);
    if ($dbh->err) { 
        carp "insert_or_update($sql) ". $dbh->errstr . "\n";
        return $dbh->errstr; 
    }
    my $rv = $sth->execute;
    if ($dbh->err) { 
        carp "insert_or_update($sql) ". $dbh->errstr . "\n";
        return undef;
    }

    $sth->finish;
    return $rv;
}

=item sql_column(table,[key_col,val_col],{where}) 

Returns reference to hash.  Hash has form C<$hash{key_val}={val_val}>

If multiple matches are found for key_col, only the last one is kept.

Usage is the same as sql_rows() -- See for Usage.

    $OldDevices = sql_column('device',['ip','layers']);

Creates the hash %$OldDevices where the key is the IP address and the Value is the Layers

=cut

sub sql_column {
    my %hash;
    my $sth = sql_query(@_);
    my $arrayref =  $sth->fetchall_arrayref;
    foreach my $arr (@$arrayref){
        my $idx = $arr->[0];
        my $val = $arr->[1];
        next unless defined $idx;
        next unless defined $val;
        $hash{$idx} = $val;
    }

    return \%hash;
}

=item sql_columns(table,[key_col,val_col,...],{where}) 

Returns reference to hash.  Hash has form C<$hash{key_val}=hash of all columns}>

If multiple matches are found for key_col, only the last one is kept.

Usage is the same as sql_rows() -- See for Usage.

    $OldDevices = sql_columns('device',['ip','layers','dns']);

Creates the hash %$OldDevices where the key is the IP address and the Value is a hash
with the keys 'ip', 'layers' and 'dns'.

=cut

sub sql_columns {
    my $key_col = $_[1]->[0];
    my $sth = sql_query(@_);
    my $arrayref =  $sth->fetchall_arrayref({});
    my %hash;
    foreach my $h (@$arrayref){
        my $idx = $h->{$key_col};
        next unless defined $idx;
        $hash{$idx} = $h;
    }

    return \%hash;
}


=item sql_do(sql)

Simple wrapper to C<$dbh-E<gt>do()>

No quoting.

=cut

sub sql_do {
    my $sql = shift;
    my $dbh = &dbh;    
    
    carp("[$$] $sql") if $SQLCARP;

    return $dbh->do($sql); 
}

=item sql_begin()

Start an SQL transaction.

Pass an array reference to the list of tables that should be
locked in EXCLUSIVE mode for this transaction.  Normally, row
locking is sufficient, so no tables need be locked.  However,
netdisco's macsuck and arpnip processes perform statements like

    UPDATE table SET active='f' WHERE (ip|mac)='foo'

If two such statements are executed concurrently for the
same value of 'foo', they can visit the same rows in different
order, resulting in a deadlock.  It's tempting to say that
you can solve this by making the UPDATE only touch one row at
a time by adding "AND active" to the WHERE clause; however,
it's possible to get multiple rows with active=true and open
up the window for deadlock again.  Without a significant
rewrite, the best option is to lock the appropriate table in
exclusive mode (which still allows readers, such as the web
front end, but blocks any inserts or updates).  Since netdisco
performs updates in bulk, the table will not spend a significant
amount of time locked.

=cut

sub sql_begin {
    my $tables = shift;
    my $dbh = &dbh;    
    carp "[$$] starting a transaction" if $SQLCARP;
    
    $dbh->{AutoCommit} = 0;
    if (defined($tables)) {
        foreach my $table (@$tables) {
            sql_do("LOCK TABLE " . $table . " IN EXCLUSIVE MODE");
        }
    }
}


=item sql_commit()

Finish an SQL transaction and return to AutoCommit mode

=cut

sub sql_commit {
    my $dbh = &dbh;    
    carp "[$$] completing transaction" if $SQLCARP;
    if ($dbh->{AutoCommit}) {
        carp "AutoCommit is already on, is this dbh new?";
        return;
    }
    $dbh->commit();
    $dbh->{AutoCommit} = 1;
}

=item sql_rollback()

If an SQL transaction is in progress, roll it back
and return to AutoCommit mode.  Suitable to be called
in a generic error situation when you don't know what
has been done, since it is a noop if there is no transaction
occurring.

=cut

sub sql_rollback {
    my $dbh = &dbh;    
    carp "[$$] rolling back transaction" if $SQLCARP;
    if ($dbh->{AutoCommit}) {
        carp "AutoCommit is already on, no transaction in progress?" if $::DEBUG;
        return;
    }
    $dbh->rollback();
    $dbh->{AutoCommit} = 1;
}

=item sql_disconnect()

Disconnect from the SQL database, e.g., before forking.

=cut

sub sql_disconnect {
    my $dbh = &dbh;
    $dbh->disconnect;
}

=item sql_hash(table, [columns], {where}) 

Returns reference to hash representing single row.

Usage is the same as sql_rows() -- See for Usage.

    my $hashref = sql_hash('device',['ip','ports'], {'ip'=>'127.0.0.1'});

=cut

sub sql_hash {
    my $sth = sql_query(@_);
    # If the query failed, return undef.
    return undef if (!defined($sth));
    # Otherwise, return the first matching row (or undef)
    return $sth->fetchrow_hashref();
}

=item sql_match(text,exact_flag)

Parses text to substitue wildcards * and ? for % and _

Optional exact_flag specifies whether or not to search for that exact text
search or to do a *text*.

Default is non_exact.

=cut

sub sql_match{
    my $text = shift;
    my $exact_flag = shift || 0;

    return undef unless defined $text;

    # Trim white space
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    # Leave IS (not) NULL queries alone
    unless ($text =~ /^is\s+(not)?\s*null$/i){
        # Otherwise, make  * and ? into % and _
        $text =~ s/[*]+/%/g;
        $text =~ s/[?]/_/g;
        # Non-exact text means we add a * to both sides.
        $text = '%'. $text . '%' unless $exact_flag;
        $text =~ s/\%+/%/g;
    }

    return $text;
}

=item sql_rows(table, [columns] , {where} ,OR, orderbystring)

Returns a reference to an array of hash references. Each hash reference is the
return of C<$dbh-E<gt>fetchrow_hashref>

Supports

    * Joins
    * Pattern Matching
    * NULL/NOT NULL 
    * Boolean OR or AND criteria
    * Auto-Quotes all values and Override
    * IN (list) and NOT IN (list) clauses

Pass a true value for the OR argument to join constraints in the WHERE clause by 
OR instead of AND.

=over

=item SIMPLE QUERY:

Select info for every device:

    $matches = sql_rows('device',['ip','dns','uptime]);

=item  DISABLE AUTOQUOTING: 

Pass the where value as a reference:

    sql_rows('device d, device e',['d.ip,d.dns,e.ip,e.dns'],
            {'d.dns' => \'e.dns'});

Creates the SQL:

    SELECT d.ip,d.dns,e.ip,e.dns FROM device d, device e WHERE d.dns = e.dns;

This also leaves a security hole if the where value is coming from the outside
world because someone could stuff in C<'dog'>;delete from node where true;...>
as a value.   If you turn off quoting make sure the program is feeding the where
value.

=item DISABLE AUTOQUOTING AND CONNECTOR

Pass the where value as a double scalar reference:

    sql_rows('device',['*'], {'age(creation)' => \\"< interval '1 day'"})

Creates the sql:

   SELECT * FROM device WHERE age(creation) < interval '1 day';

=item  NULL VALUES

Select all the devices without reverse dns entries:

  $matches = sql_rows('device',['ip','name'],{'dns'=>'IS NULL'});

=item  JOINS

    $matches = sql_rows('device d left join device_ip i on d.ip = i.ip',
                        ['distinct(d.ip)','d.dns','i.alias','i.ip'],
                        {'d.ip/i.alias'=>'127.0.0.1', 'd.dns/i.dns' => 'dog%'},
                        1);

Selects all rows within C<device> and C<device_ip> where 
C<device_ip.alias> or C<device.ip> are C<localhost>
or C<device_ip.dns> or C<device.dns> has C<dog> in it.

Where columns with slashes are split into separate search terms combined with C<OR>:

   { 'd.ip/i.alias' => '127.0.0.1' } 

Creates the SQL

   "WHERE (d.ip = '127.0.0.1' OR i.alias = '127.0.0.1')"

=item  MULTIPLE CONTSTRAINTS ON SAME COLUMN

Pass the where values as an array reference

    $matches = sql_rows('device',['ip'],{'dns' => ['cat%','-g%'] },1 );

Creates the SQL:

    SELECT ip FROM device WHERE (dns like 'cat%') OR (dns like '-g%');

=item  IN (list) CLAUSE

Pass the value as a double array reference. Values are auto-quoted.

Single array reference is for creating multiple C<WHERE> entries (see above)

    $matches = sql_rows('node',['mac'], {'substr(mac,1,8)' => [['00:00:00','00:00:0c']]})

Creates the SQL:

    SELECT mac FROM node WHERE (substr(mac,1,8) IN ('00:00:00','00:00:0c'));

=item  NOT IN (list)

Pass the value as a double array reference.  Prepend one of the array values with a C<!>

    $matches = sql_rows('device',['name'], {'vendor' => [['!cisco','hp']]  });

Will find all devices that are neither cisco or hp.

=item  ORDER BY CLAUSE

    $matches = sql_rows('device',['ip','dns'], undef, undef, 'order by dns limit 10'); 

=back

=cut

sub sql_rows {
    my $sth = sql_query(@_);
    # If the query failed, return undef.
    return undef if (!defined($sth));
    # calling fetchall_ with {} forces it to return hashes
    return $sth->fetchall_arrayref({});
}

=item sql_query(table, [columns] , {where} ,OR, orderbystring)

Returns a DBI state handle on which the SQL query has been prepare()d and
execute()d.  This function is good for large queries instead of
sql_rows(), as the whole result set does not need to be read into
memory.

Code such as

    my $nodes = sql_rows(...);
    foreach my $row (@$nodes) {
        ...
    }

can be replaced by

    my $sth = sql_query(...);
    while (my $row = $sth->fetchrow_hashref()) {
        ...
    }

The arguments are exactly the same as sql_rows().

=cut

sub sql_query {
    my $dbh = &dbh;

    my ($table,$column,$wherehash,$boolean,$orderby) = @_;

    my $sql = sprintf("SELECT %s FROM $table", join(',',@$column));

    if (defined $wherehash and scalar(keys %$wherehash)) {
        my @where;
        foreach my $index (keys %$wherehash){
            my $val = $wherehash->{$index};
        
            # If we're looking for one thing only, stick it in
            #   an array to match if we were looking for more.
            if (ref $val ne 'ARRAY'){
                $val = [$val];
            }

            my @indicies = ($index =~ m#/#) ?
                          split('/',$index) :
                           ($index);

            foreach my $val_orig (@$val){
                my $con = ''; my $quote = 1; my $not = 0;
                my $value = $val_orig; 

                # Double reference ommits the connector
                if (ref($value) eq 'REF' and ref($$value) eq 'SCALAR') {
                    $value = $$$value;
                    $con = '';
                    $quote = 0;
                # passing reference to where value is a column name, no quoting.
                #   optional ! in front for not
                } elsif (ref $value eq 'SCALAR'){
                    $quote = 0;
                    $value = $$value;
                    $con = '=';
                    if ($value =~ /^!(.*)$/){
                        $value = $1;
                        $con = '!=';
                    } 
                } elsif (ref $value eq 'ARRAY'){
                    # Let's not modify passed argument.
                    my @val_copy = @$value;
                    # Empty list?  Instead of forming a malformed
                    # query, just return nothing.
                    if (!@val_copy) {
                        return undef;
                    }
                    $con = 'IN';
                    my $newvalue = "(";
                    foreach my $inval (@val_copy){
                        # check for not in list
                        if ($inval =~ s/^!//){
                            $con = 'NOT IN';
                        }
                        $inval = $dbh->quote($inval);
                    }
                    $newvalue .= join(',',@val_copy);
                    $newvalue .= ")";
                    $value = $newvalue;
                } elsif ($value =~  m/^\s*is\s+(not)?\s*null$/i ){
                    $con = '';
                } elsif ($value =~ m/\%/ ) {
                    if ($value =~ /^!(.*)$/){
                        $value = $1;
                        $not = 1;
                    }
                    # Regex matching
                    $con = $not ? 'not ilike' : 'ilike';
                    $value = $dbh->quote($value) if $quote;

                    # Change the column to cast to text
                    @indicies = map { "${_}::text" } @indicies;
                } else {
                    if ($value =~ /^!(.*)$/){
                        $value = $1;
                        $con = '!=';
                    } elsif ($con eq '') {
                        $con = '=';
                    }
                    $value = $dbh->quote($value) if $quote;
                }

                my @to_where;
                foreach my $ind (@indicies) {
                    push (@to_where, "$ind $con $value");
                }
                push(@where, '('. join(' OR ',@to_where) . ')' );
            }
        }

        my $joiner = 'AND';
        if (defined $boolean and $boolean) {
            $joiner = 'OR';    
        }
        $sql .= sprintf(" WHERE %s", join(" $joiner ",@where));
    }
    
    # Just tag it on there for now.
    $sql .= " $orderby" if (defined $orderby);

    # Certain devices were null padding and postgres barfs on nulls in text fields.
    $sql =~ s/\0//g;

    carp("[$$] $sql") if $SQLCARP;

    my $sth = $dbh->prepare($sql);
    if (!defined $sth) {
        carp("sql_query($sql) - $DBI::errstr\n");
        return undef;
    }
    $sth->execute;

    return $sth;
}

=item sql_scalar(table,[column],{where}) 

Returns a scalar of value of first column given.

Internally calls C<sql_hash()> which calls C<sql_rows()>

All arguments are passed directly to C<sql_hash()>

    my $count_ip = sql_scalar('device',['COUNT(ip)'],{'name' => 'dog'});

=cut

sub sql_scalar {

    my $row = sql_hash(@_) or return;
    
    foreach my $key (keys %$row){
        return $row->{$key};
    }
    
    # Blank row
    return undef;
}

=item sql_vacuum(table,%opts)

Runs a VACUUM ANALYZE if we are Postgres

Pass the table name as '' if you want to vacuum all tables.

Options:

    verbose => 1  (set if DEBUG)
    full    => 1

=cut

sub sql_vacuum{
    my $table = shift;
    my %opts  = @_;
    my $print = (defined $opts{print} and $opts{print}) ? 1 : 0;
    
    return 1 if $CONFIG{'vacuum_no'};

    # no rated r allowed
    if ($DB eq 'Pg'){
        my $sql = (defined $opts{full}) ? 'VACUUM FULL ANALYZE' : 'VACUUM ANALYZE';
        $sql .= ' VERBOSE' if (defined $opts{verbose} or (defined $::DEBUG and $::DEBUG));
        $sql .= " $table";
        
        print "sql_vacuum($table) " if $print;
        
        my $time1 = time;
        my $rv= sql_do($sql);    
        my $time2 = time;
        my $time = $time2-$time1;
        
        print " $time seconds.\n" if $print;
    }
}

#  Debug routines

sub dump_interfaces {
    my $device = shift;


    my $interfaces = $device->interfaces();
    my $i_type     = $device->i_type();
    my $i_ignore   = $device->i_ignore();

    foreach my $if (keys %$interfaces) {
        my $port = $interfaces->{$if};
        my $type = $i_type->{$if};
        $port = defined $port ? $port : '[No Port]';
        print "$if [$type] : $port";
        print " (ignored)" if exists $i_ignore->{$if};
        print "\n";

    }

}

sub dump_globals {
    my $self=shift;
    my $globals = $self->globals();

    print "Dumping Globals : \n";
    foreach my $glob (sort keys %$globals){
        print  "\t$glob : " . $self->$glob() . "\n";
    }

}

=item homepath(config,[default])

Return the full path of the given file as specified
in the config file by prepending $CONFIG{home} to it, if
it doesn't already start with a slash.  If no value is specified
in the config file, the default is used.

=cut

sub homepath($;$) {
    my $cfgitem = shift;
    my $default = shift;
    my $item = $CONFIG{$cfgitem} || $default;
    my $home = $CONFIG{home} || '/usr/local/netdisco';
    return undef unless defined($item);
    if ($item =~ m,^/,) {
        return $item;
    } else {
        $home =~ s,/*$,,;
        return $home . "/" . $item;
    }
}

=item tryuse(module,%opts)

Try to use the given module.

Returns two values: success / failure, and the error message if failure.
Caches values if it's non fatal.

Options:

    ver => version of module required
    die => 1 if you want to die instead of recover yourself

=cut

my %tryuseok;
sub tryuse($%) {
    my $mod = shift;
    my %args = @_;
    my $ok = 1;
    my $msg = undef;

    if (defined($tryuseok{$mod})) {
        ($ok, $msg) = @{$tryuseok{$mod}};
    } else {
        if (defined($args{ver})) {
            eval "use $mod $args{ver}";
        } else {
            eval "use $mod";
        }
        if ($@) {
            $msg = "You need the $mod perl module";
            if ($args{ver}) {
                $msg .= ", version $args{ver} or newer";
            }
            $msg .= ".\nPlease install it and try again.\n\n" . $@;
            $ok = 0;
        }
    }
    if ($ok == 0 && $args{die}) {
        die $msg;
    }
    my $rv = [ $ok, $msg ];
    $tryuseok{$mod} = $rv;
    return $rv;
}

1;

=back

=cut
