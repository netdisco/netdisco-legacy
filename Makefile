# Makefile 
# Must run w/ gmake
# $Id$

POD2TEXT = /usr/bin/pod2text 
POD2MAN  = /usr/bin/pod2man
POD2HTML = /usr/bin/pod2html

SNMPLIBS := $(shell find SNMP -name "*.pm")

all:
	echo "Make sure you are using GNU Make (gmake).  If you're on Linux you are."
	echo "Available targets: doc,snmp,oui"

back: 
	tar cvfz $(HOME)/netdisco.tar.gz *

doc: $(SNMPLIBS) INSTALL README api_doc UPGRADE
	cd doc && ln -fs ../README* ../INSTALL .
	rm -f pod2htm*

# Makes documentation for all .pm's 
$(SNMPLIBS):
	echo "Making Docs for $@..."
	$(POD2MAN)  $@ > doc/$(subst /,-,$(@:.pm=.man))
	$(POD2TEXT) $@ > doc/$(subst /,-,$(@:.pm=.txt))
    # Adds the <%text> </%text> tags to the HTML for mason
	$(POD2HTML) $@ | bin/doc_munge > html/doc/$(subst /,-,$(@:.pm=.html))

UPGRADE: doc/UPGRADE.pod
	echo "Creating UPGRADE"
	$(POD2TEXT) -l doc/UPGRADE.pod > UPGRADE
	$(POD2HTML) doc/UPGRADE.pod | bin/doc_munge > html/doc/UPGRADE.html
	$(POD2HTML) doc/UPGRADE.pod > doc/UPGRADE.html

INSTALL: doc/INSTALL.pod
	echo "Creating INSTALL"
	$(POD2TEXT) -l doc/INSTALL.pod > INSTALL
	$(POD2HTML) doc/INSTALL.pod | bin/doc_munge > html/doc/INSTALL.html
	$(POD2HTML) doc/INSTALL.pod > doc/INSTALL.html

api_doc:
	echo "Creating Backend API docs"
	$(POD2HTML) netdisco | bin/doc_munge > html/doc/netdisco-api-backend.html
	$(POD2TEXT) netdisco > README-API-BACKEND
	echo "Creating Shared API docs"
	$(POD2HTML) netdisco.pm | bin/doc_munge > html/doc/netdisco-api-shared.html
	$(POD2TEXT) netdisco.pm > README-API-SHARED

README: doc/README.pod
	echo "Creating README"
	$(POD2TEXT) -l doc/README.pod > README
	$(POD2HTML) --norecurse --htmlroot=/netdisco/doc doc/README.pod | bin/doc_munge > html/doc/README.html
	$(POD2HTML) doc/README.pod > doc/README.html

count:
	wc html/*.html html/auto* html/doc/auto* `find . -name "*.pm"` sql/*.sql netdisco

snmp: SNMP
	cd SNMP
	echo "Updating SNMP::Info"
	echo "Hit Return at Password Prompt"
	cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/snmp-info login
	cvs -z3 -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/snmp-info update

SNMP:
	echo "Getting newest (cvs) version of SNMP::Info"
	echo "Hit Return at Password Prompt"
	cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/snmp-info login
	cvs -z3 -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/snmp-info co snmp-info
	mv -f snmp-info SNMP

oui:
	echo "Downloading oui.txt from ieee.org"
	lynx -source http://standards.ieee.org/regauth/oui/oui.txt > oui.txt
	./netdisco -O

.PHONY: back docs $(SNMPLIBS) api_doc count snmp oui

.SILENT:
