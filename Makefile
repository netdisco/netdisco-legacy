# Makefile 
# Must run w/ gmake

POD2TEXT = pod2text 
POD2MAN  = pod2man
POD2HTML = pod2html

LIBS := $(wildcard *.pm) $(shell find SNMP -name "*.pm")

all:
	echo "Available options are back,doc,count"

.PHONY: back
back: 
	tar cvfz $(HOME)/netdisco.tar.gz *

.PHONY: doc $(LIBS)
doc: $(LIBS) readme install_doc

# Adds the <%text> </%text> tags to the HTML for mason
$(LIBS):
	echo "Making Docs for $@..."
	$(POD2MAN)  $@ > doc/$(subst /,-,$(@:.pm=.man))
	$(POD2TEXT) $@ > doc/$(subst /,-,$(@:.pm=.txt))
	$(POD2HTML) $@ | sed  -e '1s/^/<%text>!/;1y/!/\n/' -e '$$ G;$$ s/$$/<\/%text>/' > html/doc/$(subst /,-,$(@:.pm=.html))

.PHONY: install_doc
install_doc:
	echo "Creating INSTALL"
	$(POD2TEXT) -l INSTALL.pod > INSTALL
	$(POD2HTML) INSTALL.pod > html/doc/INSTALL.html

.PHONY: readme
readme:
	echo "Creating README"
	$(POD2TEXT) -l README.pod > README
	$(POD2HTML) --htmlroot=/netdisco/doc --podpath=.  README.pod > html/doc/README.html

.PHONY: test 
test:
	perl -cw netdisco.test

.PHONY: count
count:
	wc html/*.html html/auto* html/doc/auto* `find . -name "*.pm"` sql/* netdisco

.SILENT:
