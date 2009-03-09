#/bin/sh
# Netdisco - CentOS Install Script
# $Id$

echo ""
echo "     Netdisco CentOS Install Script"
echo ""
echo "     This script will install Netdisco on a stock CentOS release 4.4"
echo "     installation using apache2 and mod_perl2."
echo ""
echo ""
echo "     UNSUPPORTED -  Please use at your own risk.   "
echo "     Parts of this script were originally contributed by Kaven Rousseau and was modified for CentOS by Walter Gould."
echo ""
echo -n "     Hit Return to continue or Ctrl-C to exit : "
read foo

echo ""
echo ""
echo ""
echo ""
echo "Please read the below items that will help you to run this script and get netdisco installed:"
echo ""
echo ""
echo "1)  This script uses CPAN (Comprehensive Perl Archive Network) to install the needed perl modules."
echo "    If you have not used CPAN before on the machine you are about to install netdisco on, CPAN will walk"
echo "    you through a few steps in order to configure itself. There is one option that will help you in"
echo "    installing the perl modules.  It is the 'prerequisites_policy'.  Set the 'prerequisites_policy'"
echo "    option to 'follow' during CPAN configuration."  
echo ""
echo ""
echo "2)  During the installation of one of the perl modules, you are asked for the path of httpd and"
echo "    of apxs.  On CentOS - both the httpd and apxs binaries are located in /usr/sbin."
echo ""
echo ""
echo "3)  During the installation of another of the perl modules, you will be asked if you want to"
echo "    'Skip the test suite?'  You should answer 'Yes' to this.  If not, the test will fail and"
echo "    the module will fail to install properly."
echo ""
echo ""
echo "4)  Make sure that 'selinux' is disabled or configured properly in order to allow netdisco"
echo "    to run properly.  This script assumes that selinux has been disabled."
echo ""
echo ""
echo "5)  Towards the end of the install script, netdisco attempts to discover devices on your"
echo "    network.  Please be patient and allow time for it to discover the devices on your network."
echo "    It may take some time for the discovery process to complete."
echo ""
echo ""
echo "6)  Sometimes for whatever unkown reason - either httpd or postgresql fails to restart"
echo "    properly at the end of the install process.  If this appears to happen, you may need"
echo "    to manually restart these after the script has finished.  Do a 'ps -ef | grep httpd'"
echo "    or a 'ps -ef | grep postgresql' to see if they are running.  To start them you can"
echo "    run '/etc/init.d/httpd start' or '/etc/init.d/postgresql start'." 
echo ""
echo ""
echo -n "     Hit Return to continue or Ctrl-C to exit : "
read foo
echo ""
echo ""



# 
# These urls will change over time. You may need to update them if you find they are outdated.
#
EXTRAS='http://centos.karan.org/kbsingh-CentOS-Extras.repo'
NETDISCO='http://easynews.dl.sourceforge.net/sourceforge/netdisco/netdisco-0.95_with_mibs.tar.gz'
MODPERL='http://search.cpan.org/CPAN/authors/id/P/PG/PGOLLUCCI/mod_perl-2.0.3.tar.gz'
GRAPH='http://search.cpan.org/CPAN/authors/id/J/JH/JHI/Graph-0.80.tar.gz'
NETSNMP='http://internap.dl.sourceforge.net/sourceforge/net-snmp/net-snmp-5.3.pre4.tar.gz'
SNMPINFO='http://umn.dl.sourceforge.net/sourceforge/snmp-info/SNMP-Info-1.04.tar.gz'
LIBAPREQ2='http://search.cpan.org/CPAN/authors/id/J/JO/JOESUF/libapreq2-2.06-dev.tar.gz'
HTMLMASON='http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/HTML-Mason-1.3101.tar.gz'
MASONX='http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/MasonX-Request-WithApacheSession-0.30.tar.gz'
APACHE2HANDLER='http://search.cpan.org/CPAN/authors/id/B/BE/BEAU/MasonX-Apache2Handler-0.05.tar.gz'


# Get CentOs 'extras' repo file
wget $EXTRAS
mv ./kbsingh-CentOS-Extras.repo /etc/yum.repos.d/ 

# Install needed packages
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to install needed rpm packages......." 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
yum remove mod_perl
yum -y install httpd httpd-devel postgresql postgresql-server postgresql-devel elfutils-libelf-devel beecrypt-devel graphviz net-snmp net-snmp-perl mod_ssl perl-DBD-Pg perl-DBI perl-Apache-Session perl-Exception-Class perl-Compress-Zlib
sleep 3


# start postgresql
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Starting postgresql......." 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
/etc/init.d/postgresql start
sleep 3


# Edit pg_hba.conf file
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Backing up and editing postgresql files......." 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.orig
echo "# TYPE DATABASE USER IP-ADDRESS IP-MASK METHOD" > /var/lib/pgsql/data/pg_hba.conf
echo "local all all trust" >> /var/lib/pgsql/data/pg_hba.conf
echo "host all all 127.0.0.1 255.255.255.255 trust" >> /var/lib/pgsql/data/pg_hba.conf
/etc/init.d/postgresql restart
sleep 3


# Create user netdisco
/usr/sbin/useradd netdisco
sleep 3


# netdisco
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to download and unpack netdisco.........." 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
curdir=`pwd`
wget $NETDISCO 
cd /usr/local/
tar zxvf $curdir/netdisco-0.95_with_mibs.tar.gz
mv /usr/local/netdisco-0.95 /usr/local/netdisco
cd $curdir
sleep 3


# netdisco config file 
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to edit the netdisco config files.........." 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
stty -echo
echo -n "Enter Netdisco Database password: "
read netdisco_passwd
echo ""
stty echo
cat /usr/local/netdisco/netdisco.conf | sed "s/dbpassword/$netdisco_passwd/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
cat /usr/local/netdisco/netdisco_apache.conf | sed "s/PASSWORDHERE/$netdisco_passwd/g" > /tmp/netdisco_apache.conf.$$
mv -f /tmp/netdisco_apache.conf.$$ /usr/local/netdisco/netdisco_apache.conf
#
echo -n "Enter domain name: "
read domain_read
echo ""
cat /usr/local/netdisco/netdisco.conf | sed "s/mycompany\.com/$domain_read/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
#
echo -n "Enter SNMP read string: "
read snmp_read
echo ""
cat /usr/local/netdisco/netdisco.conf | sed "s/public/$snmp_read/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
#
echo -n "Enter SNMP write string: "
read snmp_write
echo ""
cat /usr/local/netdisco/netdisco.conf | sed "s/private/$snmp_write/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
sleep 3


# Making Apache2 - Modperl2 changes
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to make netdisco config changes for apache2 and mod_perl2.........."
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
#
# Edit Apache Config
echo "Include /usr/local/netdisco/netdisco_apache.conf" >> /etc/httpd/conf/httpd.conf
echo "Include /usr/local/netdisco/netdisco_apache_dir.conf" >> /etc/httpd/conf/httpd.conf
#
cat /usr/local/netdisco/netdisco_apache.conf | sed 's/#LoadModule perl_module  libexec\/apache2\/mod_perl.so/LoadModule perl_module  \/usr\/lib\/httpd\/modules\/mod_perl.so/' > /tmp/netdisco_apache.conf.$$
mv -f /tmp/netdisco_apache.conf.$$ /usr/local/netdisco/netdisco_apache.conf
#
cat /usr/local/netdisco/netdisco_apache.conf | sed 's/#LoadModule apreq_module libexec\/apache2\/mod_apreq2.so/LoadModule apreq_module \/usr\/lib\/httpd\/modules\/mod_apreq2.so/' > /tmp/netdisco_apache.conf.$$
mv -f /tmp/netdisco_apache.conf.$$ /usr/local/netdisco/netdisco_apache.conf
#
cat /usr/local/netdisco/netdisco_apache.conf | sed 's/#PerlModule/PerlModule/' > /tmp/netdisco_apache.conf.$$
mv -f /tmp/netdisco_apache.conf.$$ /usr/local/netdisco/netdisco_apache.conf
#
cat /usr/local/netdisco/html/autohandler | sed 's/$r->connection->user/$r->user/' > /tmp/autohandler.$$
mv -f /tmp/autohandler.$$ /usr/local/netdisco/html/autohandler
#
cat /usr/local/netdisco/html/login.html | sed 's/$r->connection->user($db_user->{username});/$r->user($db_user->{username});/' > /tmp/login.html.$$
mv -f /tmp/login.html.$$ /usr/local/netdisco/html/login.html
#
cd $curdir
sleep 3


echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Creating Netdisco database tables" 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
#create db
cd /usr/local/netdisco/sql
./pg --init
#
cd $curdir
sleep 3


# install perl modules
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to install perl modules - this will take a while........"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
perl -MCPAN -e 'install Bundle::CPAN'
perl -MCPAN -e 'install Apache::DBI'
perl -MCPAN -e 'install DB_File'
perl -MCPAN -e 'install Apache::Test'
perl -MCPAN -e 'install Storable'
perl -MCPAN -e 'install HTML::Entities'
perl -MCPAN -e 'install HTML::Mason'
perl -MCPAN -e 'force install MasonX::Request::WithApacheSession'
perl -MCPAN -e 'install Net::NBName'
perl -MCPAN -e 'install Heap::Elem'
perl -MCPAN -e 'install ExtUtils::XSBuilder::ParseSource'
#
wget $HTMLMASON 
tar zxvf HTML-Mason-1.3101.tar.gz
cd ./HTML-Mason-1.3101
perl Makefile.PL && make && make install
cd $curdir
# 
wget $MASONX 
tar zxvf MasonX-Request-WithApacheSession-0.30.tar.gz
cd ./MasonX-Request-WithApacheSession-0.30
perl Makefile.PL && make && make install
cd $curdir
#
wget $GRAPH
tar zxvf Graph-0.80.tar.gz
cd ./Graph-0.80
perl Makefile.PL && make && make install
cd $curdir
#
wget $APACHE2HANDLER
tar zxvf MasonX-Apache2Handler-0.05.tar.gz
cd ./MasonX-Apache2Handler-0.05
perl Makefile.PL && make && make install
cd $curdir
#
wget $MODPERL
tar zxvf mod_perl-2.0.3.tar.gz
cd ./mod_perl-2.0.3
perl Makefile.PL MP_APXS=/usr/sbin/apxs && make && make install
cd $curdir
#
wget $LIBAPREQ2 
tar zxvf libapreq2-2.06-dev.tar.gz 
cd ./libapreq2-2.06-dev
perl Makefile.PL --with-apache2-apxs=/usr/sbin/apxs && make && make install
cd $curdir
#
perl -MCPAN -e 'install GraphViz'
perl -MCPAN -e 'install Params::Validate'
perl -MCPAN -e 'install Class::Container'
perl -MCPAN -e 'force install Apache::Test'
perl -MCPAN -e 'force install Apache::Session::Wrapper'
#
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Editing Mason perl module........"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
chmod 644 /usr/lib/perl5/site_perl/5.8.5/HTML/Mason/ApacheHandler.pm
cat /usr/lib/perl5/site_perl/5.8.5/HTML/Mason/ApacheHandler.pm | sed "/require Apache2::RequestRec;/ {G;s/$/require Apache2::Connection;/;}" > /tmp/ApacheHandler.$$
mv -f /tmp/ApacheHandler.$$ /usr/lib/perl5/site_perl/5.8.5/HTML/Mason/ApacheHandler.pm
sleep 3
echo ""
echo ""
echo "Finished installing perl modules........"
echo ""
echo ""
sleep 3
#


# snmp::info
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Installing SNMP::Info........"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
cd $curdir
wget $SNMPINFO 
tar zxvf SNMP-Info-1.04.tar.gz
cd SNMP-Info-1.04
perl Makefile.PL
make install
cd $curdir
echo ""
echo ""
echo "Finished installing SNMP::Info........"
echo ""
echo ""
sleep 3


# oui database
cd /usr/local/netdisco/
#./netdisco -O
gmake oui
cd $curdir
echo ""
echo ""
echo "Finished installing OUI database........"
echo ""
echo ""
sleep 3



# crontab
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to setup netdisco crontab......"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo -n "Enter center CDP device for network discovery: "
read center_dev
cat /usr/local/netdisco/netdisco.crontab | sed "s/center_network_device/$center_dev/g" > /tmp/netdisco.crontab.$$
mv -f /tmp/netdisco.crontab.$$ /usr/local/netdisco/netdisco.crontab
crontab -u netdisco /usr/local/netdisco/netdisco.crontab
sleep 3
echo ""
echo ""
echo "Finished setting up netdisco crontab........"
echo ""
echo ""
sleep 3


# startup
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Setting up startup script......"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
ln -s /usr/local/netdisco/bin/netdisco_daemon /etc/init.d/netdisco
/sbin/chkconfig netdisco on

sleep 3

# some other stuff - do we need this...?
mkdir -p /usr/local/netdisco/data/logs
chown -R netdisco:netdisco /usr/local/netdisco/
sleep 3

/etc/init.d/postgresql start
/etc/init.d/httpd start

# Start postgres and httpd at system startup 
/sbin/chkconfig postgresql on 
/sbin/chkconfig httpd on 

# create netdisco user - and start netdisco
/usr/local/netdisco/netdisco -u admin

# Discover, macsuck and graph process
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Netdisco is about to discover your network, perform a macsuck on each device,"  
echo " and setup your network graph."  
echo ""  
echo " This portion of the install process may take some time, depending on the size of"
echo " network.  Please be patient and don't cancel out of it.  This would be a good time"  
echo " to get up and take a break, get a drink or go to lunch...."  
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
sleep 10
/usr/local/netdisco/netdisco -r $center_dev
/usr/local/netdisco/netdisco -m
/usr/local/netdisco/netdisco -g
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Starting up Netdisco front-end"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
/etc/init.d/netdisco start
echo ""
echo ""
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo " PLEASE NOTE: If selinux is enabled, you will need to disable it in"
echo " /etc/selinux/config and then reboot your server in order to run"
echo " netdisco successfully."
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo ""
echo "Netdisco Installation completed!!!!"
echo ""
echo ""
ipaddress=`/sbin/ifconfig eth0 | grep "inet addr:" | cut -c21-36 | cut -d' ' -f1`
echo "Login via https://$ipaddress/netdisco/"
echo ""
echo ""
echo "Enjoy!!!"
