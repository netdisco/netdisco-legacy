#!/usr/bin/perl -w
# Tests partial table lookups

use lib qw(/usr/local/netdisco/);
use SNMP::Info;
$|=1;

print "Perl Version $].  SNMP : $SNMP::VERSION\n";

my $host = shift || 'commcat';
my $comm = shift || 'public';
my $ver  = shift || 2;
my $debug = shift || 1;

$ipr = new SNMP::Info(
        AutoSpecify => 1,
        Debug       => $debug,
		DestHost    => $host,
		Community   => $comm,
		Version     => $ver,
		) 
    or die "Couldn't create connection on $host pw:$comm.\n" unless defined $ipr;

my @funcs = qw/ipr_route ipr_if ipr_1 ipr_dest ipr_type ipr_proto ipr_age ipr_mask ipr_info/;

# Test partial table request

my $local_routes = $ipr->ipr_route('128.114');

print "\n\n Found ", scalar(keys %$local_routes), " routes.\n";

my $all_routes = $ipr->ipr_route();

print "\n\n Found ", scalar(keys %$all_routes), " routes.\n";

my $local_routes = $ipr->ipr_route('128.114');

# Testing caching
print "\n\n Found ", scalar(keys %$local_routes), " routes.\n";

my $all_routes = $ipr->ipr_route();

print "\n\n Found ", scalar(keys %$all_routes), " routes.\n";

foreach my $route (keys %$local_routes){
    print "  $local_routes->{$route} ($route)\n";
}

# Gather
foreach my $func (@funcs){
    $values{$func} = $ipr->$func();
}

print "Found : ",scalar(keys %{$values{ipr_route}}), " routes.\n\n";

foreach my $route (keys %{$values{ipr_route}}){
    print "$values{ipr_route}->{$route}\n";
    foreach my $func (@funcs){
        next if $func eq 'ipr_route';
        print "  $func:$values{$func}->{$route}\n";
    }
}
