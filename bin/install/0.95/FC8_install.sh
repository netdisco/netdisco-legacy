#/bin/sh
# Netdisco - Fedora Install Script
# $Id$

echo ""
echo "     Netdisco Fedora Install Script"
echo ""
echo "     This script will install Netdisco on a stock Fedora Core 8"
echo "     installation using apache2 and mod_perl2."
echo ""
echo ""
echo "     UNSUPPORTED -  Please use at your own risk.   "
echo "     This script was contributed by Kaven Rousseau and was modified for Fedora by Walter Gould."
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
echo "1)  As of 1/28/2008, all perl modules in this script are installed via yum from Fedora Updates."
echo ""
echo ""
echo "2)  During the import of the oui table into the postgres db, you will receive some errors that"
echo "    are related to foreign language characters in the oui file.  These errors can be safely"
echo "    ignored.  Also, this step may take a while b/c of the encoding difference b/t netdisco and postgresql."
echo ""
echo ""
echo "3)  Make sure that 'selinux' is disabled or configured properly in order to allow netdisco"
echo "    to run properly.  This script assumes that selinux has been disabled.  If it is not disabled,"
echo "    apache will not start up.  This url may help: http://docs.fedoraproject.org/selinux-faq-fc3/index.html#id2825880"
echo ""
echo ""
echo "4)  If apache fails to start-up after the script finishes - check to be sure selinux is disabled."
echo "    This has happened to me quite a few times. oops..."
echo ""
echo ""
echo "5)  Towards the end of the install script, netdisco attempts to discover devices on your"
echo "    network.  Please be patient and allow time for it to discover the devices on your network."
echo "    It may take some time for the discovery process to complete."
echo ""
echo ""
echo -n "     Hit Return to continue or Ctrl-C to exit : "
read foo
echo ""
echo ""



# netdisco url 
NETDISCO='http://easynews.dl.sourceforge.net/sourceforge/netdisco/netdisco-0.95_with_mibs.tar.gz'


# Install needed packages
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to install needed rpm packages......." 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
yum -y install wget make httpd httpd-devel postgresql postgresql-server postgresql-devel graphviz net-snmp net-snmp-perl mod_perl mod_perl-devel mod_ssl perl-DBI perl-Apache-DBI perl-DBD-Pg perl-Apache-Session perl-HTML-Parser perl-HTML-Mason perl-Graph perl-GraphViz perl-Compress-Zlib perl-libapreq2 perl-SNMP-Info perl-Net-NBName perl-MasonX-Request-WithApacheSession 
sleep 3



# start postgresql
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Starting postgresql......." 
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
/sbin/service postgresql initdb
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
#
cat /usr/local/netdisco/netdisco.conf | sed "s/timeout         = 90/timeout         = 180/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
#
cat /usr/local/netdisco/netdisco.conf | sed "s/macsuck_timeout = 90/macsuck_timeout = 180/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
#
cat /usr/local/netdisco/netdisco.conf | sed "s/graph           = html\/netmap.gif/#graph           = html\/netmap.gif/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
#
cat /usr/local/netdisco/netdisco.conf | sed "s/#graph_png       = html\/netmap.png/graph_png       = html\/netmap.png/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
#
#cat /usr/local/netdisco/netdisco.conf | sed "s/#db_Pg_env/db_Pg_env/g" > /tmp/netdisco.conf.$$
#mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
#
sleep 3


# Making Apache2 - Modperl2 changes
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " About to make netdisco config changes for apache2 and mod_perl2."
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


echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Editing Mason perl module........"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
chmod 644 /usr/lib/perl5/vendor_perl/5.8.8/HTML/Mason/ApacheHandler.pm
cat /usr/lib/perl5/vendor_perl/5.8.8/HTML/Mason/ApacheHandler.pm | sed "/require Apache2::RequestRec;/ {G;s/$/require Apache2::Connection;/;}" > /tmp/ApacheHandler.$$
mv -f /tmp/ApacheHandler.$$ /usr/lib/perl5/vendor_perl/5.8.8/HTML/Mason/ApacheHandler.pm
sleep 3


# oui database
cd /usr/local/netdisco/
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
echo " PLEASE NOTE: If selinux is enabled, you will need to disable it"
echo " in order to run netdisco/apache successfully."
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
