#!/usr/bin/make -f

GUIDE = userguide

# Define the languages to build.
# manually:
# LANGUAGES := de en
# or automatically:
LANGUAGES := $(patsubst src/$(GUIDE).%.sgml,%,$(wildcard src/$(GUIDE).*.sgml))

# Implicit rules for the various documentation formats
# The automatic variable $* contains the part of the target that matched the %.
# Here it is the language.
html-%.stamp: src/$(GUIDE).%.sgml out/%/html
	cd src && rm -rf ../out/$*/html/* $(GUIDE).$* && db2html $(GUIDE).$*.sgml && mv $(GUIDE).$*/* ../out/$*/html/
	ln -sf book1.html out/$*/html/index.html
	cp src/$(GUIDE)-installconfig-config-webmin-loginscreen.eps out/$*/html/
	cp src/$(GUIDE)-networkbasics-protocols-x-flow.eps out/$*/html/
	touch $@
dvi-%.stamp: src/$(GUIDE).%.sgml out/%/dvi
	cd src && db2dvi $(GUIDE).$*.sgml && mv *dvi ../out/$*/dvi
	cp src/$(GUIDE)-installconfig-config-webmin-loginscreen.eps out/$*/dvi/
	cp src/$(GUIDE)-networkbasics-protocols-x-flow.eps out/$*/dvi/
	touch $@
pdf-%.stamp: ps-%.stamp out/%/pdf
	ps2pdf out/$*/ps/$(GUIDE).$*.ps out/$*/pdf/$(GUIDE).$*.pdf
	touch $@
ps-%.stamp: dvi-%.stamp out/%/ps
	cd out/$*/dvi && dvips $(GUIDE).$*.dvi -o ../ps/$(GUIDE).$*.ps
	touch $@
ps-gz-%.stamp: ps-%.stamp out/%/ps
	cd out/$*/ps && gzip -c $(GUIDE).$*.ps > $(GUIDE).$*.ps.gz
	touch $@
sgml-%.stamp: src/$(GUIDE).%.sgml out/%/sgml
	cd src && cp $(GUIDE).$*.sgml ../out/$*/sgml
	cp src/$(GUIDE)-installconfig-config-webmin-loginscreen.eps out/$*/sgml/
	cp src/$(GUIDE)-networkbasics-protocols-x-flow.eps out/$*/sgml/
	touch $@

# Implicit rules for the out/* directories.
out/%/dvi:
	mkdir -p $@
out/%/html:
	mkdir -p $@
out/%/pdf:
	mkdir -p $@
out/%/ps:
	mkdir -p $@
out/%/sgml:
	mkdir -p $@

# The dependencies of the all target have to be in an order so that
# no dependency depends from a dependency right from it. Otherwise
# some of the dependencies are built more than once.
all: html-all dvi-all ps-all pdf-all ps-gz-all sgml-all

# -all targets. They depend on all language specific targets of the same type,
# i. e. if you want to build html files of all languages, type "make html-all".
html-all: $(foreach LANG,$(LANGUAGES),html-$(LANG).stamp)
dvi-all: $(foreach LANG,$(LANGUAGES),dvi-$(LANG).stamp)
pdf-all: $(foreach LANG,$(LANGUAGES),pdf-$(LANG).stamp)
ps-all: $(foreach LANG,$(LANGUAGES),ps-$(LANG).stamp)
ps-gz-all: $(foreach LANG,$(LANGUAGES),ps-gz-$(LANG).stamp)
sgml-all: $(foreach LANG,$(LANGUAGES),sgml-$(LANG).stamp)

clean-%:
	rm -rf out/$*
	rm -rf src/$(GUIDE).$*
	rm -f src/$(GUIDE).$*.aux src/$(GUIDE).$*.log src/$(GUIDE).$*.tex
	rm -f *-$*.stamp

clean-all: $(foreach LANG,$(LANGUAGES),clean-$(LANG))

clean: clean-all
	rm -rf src/DBTOHTML_OUTPUT_DIR*

.PHONY: all clean clean-all html-all dvi-all pdf-all ps-all ps-gz-all sgml-all
