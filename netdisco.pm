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
use Graph::Undirected;
use DBI;
use Digest::MD5;

use vars qw/%DBH $DB %CONFIG %GRAPH %GRAPH_SPEED $SENDMAIL $SQLCARP %PORT_CONTROL_REASONS $VERSION/;
@netdisco::ISA = qw/Exporter/;
@netdisco::EXPORT_OK = qw/insert_or_update getip hostname sql_do has_layer
                       sql_hash sql_column sql_rows add_node add_arp dbh sql_match
                       all config sort_ip sort_port sql_scalar root_device log
                       make_graph is_mac user_add user_del mail is_secure in_subnet in_subnets
                       url_secure mask_to_bits bits_to_mask dbh_quote sql_vacuum/;

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
                                  "Following the takedown provision of the DMCA to limit the University's copyright liability."],
                'exploit'     => ['Remote Exploit Possible',
                                  'A remotely exploitable vulnerability posing high risk exists on the system.'],
                'polling'     => ['Excessive Polling of DNS/DHCP/SNMP',
                                  'Distinct from DoS attacks, excessive polling is often due to
                                   misconfigured systems or malfunctioning protocol stacks.  An example of
                                   this would be sustained, repetitive polling of the DHCP server for an
                                   address.'],
                'other'       => ['Other', 'Does not fit in any other catagory.  Make a <i>very</i> detailed <TT>Log</TT> entry.']
              );

=item $VERSION - Sync'ed with Netdisco releases

=cut
$VERSION = '0.94-cvs';

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
    sql_do(qq/UPDATE node SET active = 'f' WHERE mac = '$mac'/);

    # Add this entry to node table. 
    my %hash = ('switch' => $ip, 'mac' => $mac, 'port' => $port );
    insert_or_update('node', \%hash,
        { 'time_last' => scalar(localtime), 'active' => 1, 'oui' => $oui, %hash });
}

=item bits_to_mask(bits)

Takes a CIDR style network mask in number of bits (/24) and returns the older style 
bitmask.

=cut
sub bits_to_mask {
    my $bits = shift;
    return join(".",unpack("C4",pack("N", 2**32 - (2 ** (32-$bits)))));
}

=item  config() 

Reads the config file and fills the C<%CONFIG> hash.

=cut
sub config {
    my $file = shift;

    my @booleans = qw/compresslogs ignore_private_nets reverse_sysname daemon_bg
                      port_info secure_server graph_splines portctl_uplinks
                      portctl_nophones portctl_vlans macsuck_all_vlans
                     /;

    open(CONF, "<$file") or die "Can't open Config File $file. $!\n";
    my @configs=(<CONF>);    
    close(CONF);

    foreach my $config (@configs){
        chomp $config;
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
        if ($config =~ /^([a-zA-z_-]+)\s*=\s*(.*)$/) {
            $var = $1;  $value = $2;
        } 

        unless(defined $var and defined $value){
            print STDERR "Bad Config Line : $config\n";
            next;
        }

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
        if ($var =~ /^(community|community_rw)$/) {
            my @com = split(/\s*(?<!\\),\s*/,$value);
            foreach (@com){
                $_ =~ s!\\,!,!g;
            }
            $value = \@com;
        }

        if ($var eq 'node_map') {
            my $oldvalue = $CONFIG{$var};
            push (@$oldvalue, $value);
            $value = $oldvalue;
        }

        # Comma separated lists that map to defined hash keys.
        if ($var =~ /^(portcontrol|macsuck_no|admin|web_console_vendors|web_console_models|macsuck_no_vlan|arpnip_no|discover_no)$/) {
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

    *::CONFIG = \%CONFIG;
    return \%CONFIG;
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

=cut
sub getip {
    my $hostname = shift;

    my $ip;

    if ($hostname =~ /^\d+\.\d+\.\d+\.\d+$/) {
        $ip = $hostname;
    } else {
        my $testhost = inet_aton($hostname);
        return undef unless (defined $testhost and length $testhost);
        $ip = inet_ntoa($testhost);
    }
    return $ip;
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
    my ($class,$entry) = @_;

    insert_or_update('log',undef,{'class' => $class, 'entry' => $entry});
    
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
    my $wordcharword   = qr{^([^:\/.]+)[:\/\.]+([^:\/.]+)$};
    my $ciscofast      = qr{^(\D)+(\d+)[:\/\.]+([\d\.]+)(-.*)?$};

    my @a = (); my @b = ();
    
    if ($aval =~ $dotted_numeric) {
        @a = ($1,$2);
    } elsif ($aval =~ $letter_number) {
        @a = ($1,$2);
    } elsif ($aval =~ $numbers) {
        @a = ($1);
    } elsif ($aval =~ $wordcharword) {
        @a = ($1,$2);
    } elsif ($aval =~ $ciscofast){
        @a = ($1,$2,$3,$4);
    } else { 
        @a = ($aval);
    }

    if ($bval =~ $dotted_numeric) {
        @b = ($1,$2);
    } elsif ($bval =~ $letter_number) {
        @b = ($1,$2);
    } elsif ($bval =~ $numbers) {
        @b = ($1);
    } elsif ($bval =~ $wordcharword) {
        @b = ($1,$2);
    } elsif ($bval =~ $ciscofast){
        @b = ($1,$2,$3,$4);
    } else { 
        @b = ($bval);
    }

    # Equal until proven otherwise
    my $val = 0;
    while (scalar(@a) or scalar(@b)){
        my $a1 = shift @a;
        my $b1 = shift @b;

        # A has more components - wins
        unless (defined $b1){
            #warn("$a1 no b1\n");
            $val = -1;
        }

        # A has less components, loses
        unless (defined $a1) {
            #warn("$b1 no b1\n");
            $val = 1;
        }

        # carried around from the last find.
        last if $val != 0;

        if ($a1 =~ $numeric and $b1 =~ $numeric){
            $val = $a1 <=> $b1;
        } elsif ($a1 ne $b1) {
            $val = $a1 cmp $b1;
        }
        #warn ("$a1 $val $b1\n");
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
    my $G = new Graph::Undirected;

    my $devs_raw = sql_rows('device',['ip','dns']);
    my $aliases = sql_column('device_ip',['alias','ip']);
    my $links = sql_rows('device_port',['ip','remote_ip','speed','remote_type'],{'remote_ip' => 'IS NOT NULL'});

    my %devs;
    foreach my $dev (@$devs_raw){
        my $ip = $dev->{ip};
        my $dns = $dev->{dns};
        $devs{$ip} = $dns;
    }

    # Check for no topology info
    unless (scalar @$links){
        print "make_graph() - No Topology information." if $::DEBUG; 
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
                $GRAPH{$link}->{dns} = $dns;
                $GRAPH{$link}->{isdev} = $is_dev;
                $GRAPH{$link}->{seen}++;
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
                $GRAPH{$dest}->{dns} = $dns;
                $GRAPH{$dest}->{isdev} = $is_dev;
                $GRAPH{$dest}->{seen}++;
            }

            $G->add_edge($link,$dest);
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

C<%args> can have key values of { pw, admin, port }

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

=back

=head2 SQL Functions

=over

=item dbh()

Creates and returns a database handle. Creates once, then 
returns the cached copy.  

Select database handle in use by localizing C<$netdisco::DB>

=cut
sub dbh {
    unless ($DBH{$DB} && $DBH{$DB}->ping) {
        my $connect = $CONFIG{"db_$DB"}        or die "dbh() - db_$DB not found in config info.\n";
        my $user    = $CONFIG{"db_${DB}_user"} or die "dbh() - db_${DB}_user not found in config info.\n";
        my $pw      = $CONFIG{"db_${DB}_pw"}   or die "dbh() - db_${DB}_pw not found in config info.\n";
        my $options = $CONFIG{"db_${DB}_opts"} || {};
        if (defined $CONFIG{"db_${DB}_env"}) {
            my ($key,$val) = split(/\s*=>\s*/,$CONFIG{"db_${DB}_env"});
            #warn "Setting ENV{$key} to $val\n";
            $ENV{$key}=$val;
        }
        $DBH{$DB} = DBI->connect($connect,$user,$pw,$options)
            or die "Can't connect to DB. $DBI::errstr\n";
    }
    return $DBH{$DB}; 
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
            push(@where, "$index = $value ");
        }

        my $wherestr = join(' AND ',@where);

        $sql = qq/SELECT * FROM $table WHERE $wherestr/;

        carp($sql) if $SQLCARP;
        my $row = $dbh->selectrow_hashref($sql);
        carp "insert_or_update($sql) ". $dbh->errstr . "\n" if $dbh->err;

        my $diff = &hash_diff($row,$values);

        # Update
        if (defined $row and $diff) {
            $sql = sprintf("UPDATE $table SET %s WHERE $wherestr",
                join(',',map { sprintf("$_=%s",$dbh->quote($values->{$_})) } keys %$values));

            carp($sql) if $SQLCARP;

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

    carp($sql) if $SQLCARP;

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

    if ($DB eq 'Pg'){
        $rv = $sth->{pg_oid_status} || $rv;
    }
    
    $sth->finish;
    return $rv;
}

=item sql_column(table,[key_col,val_col],{where}) 

Returns reference to hash.  Hash has form C<$hash{key_val}={val_val}>

If multiple matches are found for key_col, only the last one is kept.

Supports

    * (NOT) NULL
    * Auto-Quoting Values

    $OldDevices = sql_column('device',['ip','layers']);

Creates the hash %$OldDevices where the key is the IP address and the Value is the Layers

=cut
sub sql_column {
    my $dbh = &dbh;

    my ($table,$column,$wherehash) = @_;

    my $sql = sprintf("SELECT %s FROM $table", join(',',@$column));

    if (defined $wherehash) {
        my @where;
        foreach my $index (keys %$wherehash){
            my $val = $wherehash->{$index};

            my $con = '=';

            if ($val =~  m/^\s*is\s+(not)?\s*null$/i ){
               $con = ''; 
            }

            $val = $dbh->quote($val) if $con;
            push(@where, sprintf("$index $con $val"));
        }

        $sql .= sprintf(" WHERE %s", join(' AND ',@where));
    }
    
    carp($sql) if $SQLCARP;

    my %hash;
    my $sth = $dbh->prepare($sql);
    $sth->execute;
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

=item sql_do(sql)

Simple wrapper to C<$dbh-E<gt>do()>

No quoting.

=cut
sub sql_do {
    my $sql = shift;
    my $dbh = &dbh;    
    
    carp($sql) if $SQLCARP;

    return $dbh->do($sql); 
}

=item sql_hash(table, [columns], {where}) 

Returns reference to hash representing single row.

Supports:

    * Auto-Quotes Values
    * NULL/NOT NULL
    * Pattern Matching

    my $hashref = sql_hash('device',['ip','ports'], {'ip'=>'127.0.0.1'});

=cut
sub sql_hash {
    my $dbh = &dbh;

    my ($table, $column, $wherehash) = @_;

    my $sql = sprintf("SELECT %s FROM $table", join(',',@$column));

    if (defined $wherehash) {
        my @where;
        foreach my $index (keys %$wherehash){
            my $value = $wherehash->{$index};
            unless (defined $value){
                carp("sql_hash($table,$index) value for where:$index is undef.\n");
                next;
            }
            my $con ;
            if ($value =~  m/^\s*is\s+(not)?\s*null$/i ){
                $con = '';
            } elsif ($value =~ m/\%/ ) {
                $con = 'ilike';
                $value = $dbh->quote($value);
            } else {
                $con = '=';
                $value = $dbh->quote($value);
            }

            push(@where, sprintf("$index $con $value"));
        }

        $sql .= sprintf(" WHERE %s", join(' AND ',@where));
    }
    
    carp($sql) if $SQLCARP;

    return $dbh->selectrow_hashref($sql);
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
                    # Regex matching
                    $con = $not ? 'not ilike' : 'ilike';
                    $value = $dbh->quote($value) if $quote;

                    # Change the column to cast to text
                    @indicies = map { "${_}::text" } @indicies;
                } else {
                    $con = $not ? '!=' : '=';
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

    carp($sql) if $SQLCARP;

    my $sth = $dbh->prepare($sql);
    if (!defined $sth) {
        carp("sql_rows($sql) - $DBI::errstr\n");
        return undef;
    }
    $sth->execute;

    # calling fetchall_ with {} forces it to return hashes
    return  $sth->fetchall_arrayref({});
}

=item sql_scalar(table,[column],{where}) 

Returns a scalar of value of first column given.

Internally calls C<sql_hash()>

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

    # no rated r allowed
    if ($DB eq 'Pg'){
        my $sql = (defined $opts{full}) ? 'VACUUM FULL ANALYZE' : 'VACUUM ANALYZE';
        $sql .= ' VERBOSE' if (defined $opts{verbose} or (defined $::DEBUG and $::DEBUG));
        return sql_do(qq/$sql $table/);    
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

1;

=back

=cut
