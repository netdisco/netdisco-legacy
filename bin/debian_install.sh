#/bin/sh
# Netdisco - Debian Install Script
# Written by Kaven Rousseau
# $Id$ 

echo ""
echo "[ Netdisco ] Debian Install Script"
echo ""
echo "   * This script will install Netdisco on a stock Debian 3.0 installation"
echo ""
echo "   * You _must_ read INSTALL completely first.  "
echo "     Some Manual steps are still required."
echo ""
echo "UNSUPPORTED -  Please use at your own risk.   "
echo "               This script was contributed by Kaven Rousseau and is untested."
echo ""
echo -n "Hit Return to continue or Ctrl-C to exit : "
read foo

#apt
cat /etc/apt/sources.list | sed "s/^deb cdrom/#deb cdrom/g" > /tmp/sources.list.$$
mv -f /tmp/sources.list.$$ /etc/apt/sources.list
apt-get update
apt-get upgrade
apt-get install etherconf apache apache-dev nmap bvi vim zip unzip bzip2 wget ncftp libapache-mod-perl libapache-mod-gzip libapache-dbi.perl libapache-dbi-perl libperl-dev links postgresql postgresql-dev
apt-get remove lpr
apt-get remove portmap

#get hostname
ipaddress=`ifconfig eth0 | grep "inet addr:" | cut -c21-36 | cut -d' ' -f1`

#Create user netdisco
adduser netdisco

#Groups
groupid=`cat /etc/group | grep "netdisco:x:" | cut -d':' -f3`
grep -v "netdisco:x:$groupid:" /etc/group > /tmp/group.$$
echo "netdisco:x:$groupid:eonadmin,www-data" >> /tmp/group.$$
mv -f /tmp/group.$$ /etc/group

#clear motd
> /etc/motd

#services
cp -f inetd.conf /etc/inetd.conf

#httpd.conf
cat httpd.conf | sed "s/eonnoclx01/$ipaddress/g" > /etc/apache/httpd.conf

#index.html
cp index.html /var/www/

#postgres hba
cp -f pg_hba.conf /etc/postgresql/pg_hba.conf

#netdisco
curdir="`pwd`"
cd /usr/local
tar zxvf $curdir/netdisco.tar.gz
cd $curdir

#netdisco config file
stty -echo
echo -n "Enter Netdisco Database password.. again: "
read netdisco_passwd
stty echo
cat /usr/local/netdisco/netdisco.conf | sed "s/netdisco_password_here/$netdisco_passwd/g" > /tmp/netdisco.conf.$$
mv -f /tmp/netdisco.conf.$$ /usr/local/netdisco/netdisco.conf
cat /usr/local/netdisco/netdisco_apache.conf | sed "s/netdisco_password_here/$netdisco_passwd/g" | sed "s/machine_hostname_here/$ipaddress/g" > /tmp/netdisco_apache.conf.$$
mv -f /tmp/netdisco_apache.conf.$$ /usr/local/netdisco/netdisco_apache.conf


#restart postgresql to refresh config
/etc/init.d/postgresql stop 
/etc/init.d/postgresql start

#create db
cd /usr/local/netdisco/sql
./pg_init
./pg_all
cd $curdir

#install perl modules
perl -MCPAN -e 'install Bundle::CPAN'
perl -MCPAN -e 'install DBI'
perl -MCPAN -e 'install Apache::DBI'
perl -MCPAN -e 'install DBD::Pg'
apt-get install libapache-session-perl
apt-get install libapache-request-perl
perl -MCPAN -e 'install HTML::Mason'
perl -MCPAN -e 'install MasonX::Request::WithApacheSession'
perl -MCPAN -e 'install Graph'

#install GraphViz
cd $curdir
#wget http://www.graphviz.org/pub/graphviz/graphviz-1.10.tar.gz
tar zxvf graphviz-1.10.tar.gz
cd graphviz-1.10
./configure
make
make install
cd $curdir
perl -MCPAN -e 'install GraphViz'

#net-snmp
#wget http://twtelecom.dl.sourceforge.net/sourceforge/net-snmp/net-snmp-5.0.8.tar.gz
tar zxvf net-snmp-5.0.8.tar.gz
cd net-snmp-5.0.8
./configure --with-perl-modules
make
make install
cd ..
echo "mibdirs  /usr/local/share/snmp/mibs" > /usr/local/share/snmp/snmp.conf
cd /usr/local/share/snmp
tar zxvf $curdir/mibs.tgz
cd $curdir

#snmp::info
#wget http://aleron.dl.sourceforge.net/sourceforge/snmp-info/SNMP-Info-0.6.tar.gz
tar zxvf SNMP-Info-0.?.tar.gz
cd SNMP-Info-0.?
perl Makefile.PL
make install
cd $curdir

#oui database
cd /usr/local/netdisco/
./netdisco -O
cd $curdir

#crontab
echo -n "Enter center CDP device for network discovery: "
read center_dev
cat /usr/local/netdisco/netdisco.crontab | sed "s/127.0.0.1/$center_dev/g" > /tmp/netdisco.crontab.$$
mv -f /tmp/netdisco.crontab.$$ /usr/local/netdisco/netdisco.crontab
crontab -u netdisco /usr/local/netdisco/netdisco.crontab

#startup
echo "#!/bin/bash" > /etc/init.d/netdisco
echo "su netdisco -c \"/usr/local/netdisco/netdisco -p start\"" >> /etc/init.d/netdisco
chmod +x /etc/init.d/netdisco
ln -s ../init.d/netdisco /etc/rc2.d/S99netdisco

#some other stuff
mkdir -p /usr/local/netdisco/data/logs
ln -s /bin/gzip /usr/bin/gzip
chmod o-rwx /usr/local/netdisco/*
chown netdisco.netdisco /usr/local/netdisco/netdisco*

#create netdisco user
/usr/local/netdisco/netdisco -u eonadmin
/usr/local/netdisco/netdisco -r $center_dev
/usr/local/netdisco/netdisco -m
/usr/local/netdisco/netdisco -g
apachectl restart
su - netdisco -c "/usr/local/netdisco/netdisco -p start"
echo "Installation completed."
echo "Restart server to verify if everything starts starts."
echo "login via: http://$ipaddress/netdisco/"

