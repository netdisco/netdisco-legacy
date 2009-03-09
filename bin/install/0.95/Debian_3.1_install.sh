#/bin/sh
# Netdisco - Debian Install Script
# $Id$

echo ""
echo "     Netdisco Debian Install Script"
echo ""
echo "     This script will install Netdisco Vers. 0.95 on a stock Debian"
echo "     installation using apache2 and mod_perl2."
echo ""
echo ""
echo "     UNSUPPORTED -  Please use at your own risk.   "
echo ""
echo ""
echo "     This script was originally contributed by Kaven Rousseau and" 
echo "     has been modified by Walter Gould for a Debian installation."
echo ""
echo ""
echo -n "  Hit Return to continue or Ctrl-C to exit : "
read foo

echo ""
echo ""
echo ""
echo ""
echo "Please read (and possibly print) the below items that will help you to run this script and get netdisco installed:"
echo ""
echo ""
echo "1)  This script uses CPAN (Comprehensive Perl Archive Network) to install some of the needed perl modules."
echo "    If you have not used CPAN before on the machine you are about to install netdisco on, CPAN will walk"
echo "    you through a few steps in order to configure itself. One option that will help you in"
echo "    installing the perl modules is the 'prerequisites_policy'.  Set the 'prerequisites_policy'"
echo "    option to 'follow' during CPAN configuration.  If CPAN asks if you would like to configure it a"  
echo "    second time during the installation of the perl modules, just reply 'no'.  Other perl mod's are installed"
echo "    using apt and some others are manually compiled."
echo ""
echo ""
echo "2)  You need to ensure that iptables is not blocking udp port 161 and tcp ports 80 and/or 443."
echo "    Otherwise, it will appear that netdisco is not working, when really it is your firewall that is the culprit."
echo ""
echo ""
echo "3)  This script was tested on Debian 3.1R2 using a 2.6 kernel, Apache 2.xx and mod_perl 2.02."
echo ""
echo ""
echo "4)  During the installation of the Apache::Test perl module, you are asked for the paths of the httpd"    
echo "    and of apxs binaries.  The httpd (or apache2) binary, as it is called on Debian, is located in /usr/sbin."                            
echo "    The apxs (or apxs2) binary is also located in /usr/bin/."
echo ""
echo ""
echo "5)  If you are asked for the location of the apache source, just type 'q' as apache was not compiled from source."
echo ""
echo ""
echo "6)  Towards the end of the install script, netdisco attempts to discover devices on your"
echo "    network.  Please be patient and allow time for it to discover the devices on your network."
echo "    It may take some time for the discovery process to complete."
echo ""
echo ""
echo "7)  Sometimes - either apache or postgresql fails to restart properly at the end of the"
echo "    install process.  If this appears to happen, you may need to manually restart these"
echo "    after the script has finished.  Do a 'ps -ef | grep apache2' or a 'ps -ef | grep postgresql'"
echo "    to see if they are running.  To start them you can run '/etc/init.d/apache2 start'"
echo "    or '/etc/init.d/postgresql start'." 
echo ""
echo ""
echo "8)  Configuring apache to use mod_ssl on Debian is beyond the scope of this script.  However, the libapache-mod-ssl"
echo "    package will be installed below - you just need to configure apache and mod_ssl to jive together."
echo "    The below url is a decent "How To" to get mod_ssl working with apache2 on Debian:"
echo "    http://www.michaellewismusic.com/forum/viewtopic.php?t=1475"
echo ""
echo ""
echo -n " Hit Return to continue or Ctrl-C to exit : "
read foo
echo ""
echo ""



# **** NOTE ***** 
# These urls will change over time. You may need to update them if you find they are outdated.
#
NETDISCO='http://easynews.dl.sourceforge.net/sourceforge/netdisco/netdisco-0.95_with_mibs.tar.gz'
MODPERL='http://search.cpan.org/CPAN/authors/id/P/PG/PGOLLUCCI/mod_perl-2.0.2.tar.gz'
GRAPH='http://search.cpan.org/CPAN/authors/id/J/JH/JHI/Graph-0.80.tar.gz'
NETSNMP='http://internap.dl.sourceforge.net/sourceforge/net-snmp/net-snmp-5.3.pre4.tar.gz'
SNMPINFO='http://umn.dl.sourceforge.net/sourceforge/snmp-info/SNMP-Info-1.04.tar.gz'
LIBAPREQ2='http://search.cpan.org/CPAN/authors/id/J/JO/JOESUF/libapreq2-2.06-dev.tar.gz'
HTMLMASON='http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/HTML-Mason-1.3101.tar.gz'
MASONX='http://search.cpan.org/CPAN/authors/id/D/DR/DROLSKY/MasonX-Request-WithApacheSession-0.30.tar.gz'
APACHE2HANDLER='http://search.cpan.org/CPAN/authors/id/B/BE/BEAU/MasonX-Apache2Handler-0.05.tar.gz'


# Install needed packages
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to install needed rpm packages......." 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
apt-get install -y \
apache2 apache2-prefork-dev \
postgresql postgresql-dev postgresql-client \
snmp snmpd \
beecrypt2-dev \
libperl5.8 libperl-dev \
libelfsh0-dev \
libsnmp-perl \
libapache-mod-ssl \
libgraphviz-perl \
libdbi-perl \
libdbd-pg-perl \
libapache-session-perl \
libexception-class-perl \
libnet-nbname-perl \
libheap-perl \
libextutils-xsbuilder-perl \
libparams-validate-perl \
libclass-container-perl \
libcompress-zlib-perl \

apt-get remove -y libapache2-mod-perl2
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
cp /var/lib/postgres/data/pg_hba.conf /var/lib/postgres/data/pg_hba.conf.orig
echo "# TYPE DATABASE USER IP-ADDRESS IP-MASK METHOD" > /var/lib/postgres/data/pg_hba.conf
echo "local all all trust" >> /var/lib/postgres/data/pg_hba.conf
echo "host all all 127.0.0.1 255.255.255.255 trust" >> /var/lib/postgres/data/pg_hba.conf
/etc/init.d/postgresql restart
sleep 3


# Create user netdisco
/usr/sbin/useradd netdisco
/usr/sbin/groupadd netdisco
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
echo "Include /usr/local/netdisco/netdisco_apache.conf" >> /etc/apache2/apache2.conf 
echo "Include /usr/local/netdisco/netdisco_apache_dir.conf" >> /etc/apache2/apache2.conf 
#
cat /usr/local/netdisco/netdisco_apache.conf | sed 's/#LoadModule perl_module  libexec\/apache2\/mod_perl.so/LoadModule perl_module  \/usr\/lib\/apache2\/modules\/mod_perl.so/' > /tmp/netdisco_apache.conf.$$
mv -f /tmp/netdisco_apache.conf.$$ /usr/local/netdisco/netdisco_apache.conf
#
cat /usr/local/netdisco/netdisco_apache.conf | sed 's/#LoadModule apreq_module libexec\/apache2\/mod_apreq2.so/LoadModule apreq_module \/usr\/lib\/apache2\/modules\/mod_apreq2.so/' > /tmp/netdisco_apache.conf.$$
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
echo " About to install perl modules from CPAN - this may take a while........"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
perl -MCPAN -e 'install Bundle::CPAN'
perl -MCPAN -e 'install Apache::DBI'
perl -MCPAN -e 'force install Apache::Test'
perl -MCPAN -e 'install DB_File'
perl -MCPAN -e 'install Storable'
perl -MCPAN -e 'install HTML::Entities'
perl -MCPAN -e 'install Apache::Session::Wrapper'
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
tar zxvf mod_perl-2.0.2.tar.gz
cd ./mod_perl-2.0.2
perl Makefile.PL MP_APXS=/usr/bin/apxs2 && make && make install
cd $curdir
#
wget $LIBAPREQ2 
tar zxvf libapreq2-2.06-dev.tar.gz 
cd ./libapreq2-2.06-dev
perl Makefile.PL --with-apache2-apxs=/usr/bin/apxs2 && make && make install
#
# Compile and Install Apache2::Request
cd ./glue/perl
perl Makefile.PL && make && make install
#
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Editing Mason perl module........"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
chmod 644 /usr/local/share/perl/5.8.4/HTML/Mason/ApacheHandler.pm 
cat /usr/local/share/perl/5.8.4/HTML/Mason/ApacheHandler.pm | sed "/require Apache2::RequestRec;/ {G;s/$/require Apache2::Connection;/;}" > /tmp/ApacheHandler.$$
mv -f /tmp/ApacheHandler.$$ /usr/local/share/perl/5.8.4/HTML/Mason/ApacheHandler.pm 
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
echo ""
echo ""
echo "Finished installing perl modules........"
echo ""
echo ""
sleep 3


# oui database
cd /usr/local/netdisco/
#./netdisco -O
make oui
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
cd $curdir
cat /usr/local/netdisco/bin/netdisco_daemon | sed "s/su -l/su -/g" > /tmp/netdisco_daemon.$$
mv -f /tmp/netdisco_daemon.$$ /usr/local/netdisco/bin/netdisco_daemon
chmod +x /usr/local/netdisco/bin/netdisco_daemon

ln -s /usr/local/netdisco/bin/netdisco_daemon /etc/init.d/netdisco
/usr/sbin/update-rc.d -f netdisco defaults  

sleep 3

# some other stuff - do we need this...?
mkdir -p /usr/local/netdisco/data/logs
sleep 3

#/etc/init.d/postgresql restart
sleep 3
/etc/init.d/apache2 force-reload
sleep 3

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
chown -R netdisco:netdisco /usr/local/netdisco/
chown -R www-data:www-data /usr/local/netdisco/mason/
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
echo "Netdisco Installation completed!!!!"
echo ""
echo ""
ipaddress=`/sbin/ifconfig eth0 | grep "inet addr:" | cut -c21-36 | cut -d' ' -f1`
echo "Login via http://$ipaddress/netdisco/"
echo ""
echo ""
echo "Enjoy!!!"
