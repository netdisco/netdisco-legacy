# Makefile 
# Must run w/ gmake
# $Id$

POD2TEXT = /usr/local/bin/pod2text 
POD2MAN  = /usr/local/bin/pod2man
POD2HTML = /usr/local/bin/pod2html

SNMPLIBS := $(shell find SNMP -name "*.pm")

all:
	echo "Available options are docs,snmp,oui"

back: 
	tar cvfz $(HOME)/netdisco.tar.gz *

docs: doc $(SNMPLIBS) readme install_doc api_doc
	ln -fs README doc/
	ln -fs README-API-BACKEND doc/
	ln -fs README-API-SHARED doc/
	ln -fs INSTALL doc/
	rm -f pod2htm*

doc:
	mkdir doc

# Makes documentation for all .pm's 
$(SNMPLIBS):
	echo "Making Docs for $@..."
	$(POD2MAN)  $@ > doc/$(subst /,-,$(@:.pm=.man))
	$(POD2TEXT) $@ > doc/$(subst /,-,$(@:.pm=.txt))
    # Adds the <%text> </%text> tags to the HTML for mason
	$(POD2HTML) $@ | bin/doc_munge > html/doc/$(subst /,-,$(@:.pm=.html))

install_doc:
	echo "Creating INSTALL"
	$(POD2TEXT) -l INSTALL.pod > INSTALL
	$(POD2HTML) INSTALL.pod | bin/doc_munge > html/doc/INSTALL.html

api_doc:
	echo "Creating Backend API docs"
	$(POD2HTML) netdisco | bin/doc_munge > html/doc/netdisco-api-backend.html
	$(POD2TEXT) netdisco > README-API-BACKEND
	echo "Creating Shared API docs"
	$(POD2HTML) netdisco.pm | bin/doc_munge > html/doc/netdisco-api-shared.html
	$(POD2TEXT) netdisco.pm > README-API-SHARED

readme:
	echo "Creating README"
	$(POD2TEXT) -l README.pod > README
	$(POD2HTML) --norecurse --htmlroot=/netdisco/doc README.pod | bin/doc_munge > html/doc/README.html

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

.PHONY: back docs $(SNMPLIBS) install_doc api_doc readme count snmp oui

.SILENT:
