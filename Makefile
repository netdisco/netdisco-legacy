# Makefile 
# Must run w/ gmake
# $Id$

POD2TEXT = /usr/local/bin/pod2text 
POD2MAN  = /usr/local/bin/pod2man
POD2HTML = /usr/local/bin/pod2html

LIBS := $(wildcard *.pm) $(shell find SNMP -name "*.pm")

all:
	echo "Available options are back,doc,count,snmp,oui"

back: 
	tar cvfz $(HOME)/netdisco.tar.gz *

doc: $(LIBS) readme install_doc api_doc

# Makes documentation for all .pm's 
$(LIBS):
	echo "Making Docs for $@..."
	$(POD2MAN)  $@ > doc/$(subst /,-,$(@:.pm=.man))
	$(POD2TEXT) $@ > doc/$(subst /,-,$(@:.pm=.txt))
    # Adds the <%text> </%text> tags to the HTML for mason
	$(POD2HTML) $@ | sed  -e '1s/^/<%text>!/;1y/!/\n/' -e '$$ G;$$ s/$$/<\/%text>/' > html/doc/$(subst /,-,$(@:.pm=.html))

install_doc:
	echo "Creating INSTALL"
	$(POD2TEXT) -l INSTALL.pod > INSTALL
	$(POD2HTML) INSTALL.pod > html/doc/INSTALL.html

api_doc:
	echo "Creating API-docs"
	$(POD2HTML) netdisco > html/doc/netdisco-api.html
	$(POD2TEXT) netdisco > README-API

readme:
	echo "Creating README"
	$(POD2TEXT) -l README.pod > README
	$(POD2HTML) --norecurse --htmlroot=/netdisco/doc README.pod > html/doc/README.html

test:
	perl -cw netdisco.test

count:
	wc html/*.html html/auto* html/doc/auto* `find . -name "*.pm"` sql/* netdisco

snmp:
	echo "Hit Return at Password Prompt"
	cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/snmp-info login
	cvs -z3 -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/snmp-info co snmp-info
	mv -f snmp-info SNMP

oui:
	echo "Downloading oui.txt from ieee.org"
	lynx -source http://standards.ieee.org/regauth/oui/oui.txt > oui.txt
	./netdisco -O

.PHONY: back doc $(LIBS) install_doc readme test count snmp oui

.SILENT:
