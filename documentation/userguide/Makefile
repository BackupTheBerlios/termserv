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
html-%: out/%/html
	cd src && sgml2html -l $* -s 2 $(GUIDE).$*.sgml && mv *html ../out/$*/html
dvi-%: out/%/dvi
	cd src && sgml2latex -o dvi -p a4 -l $* $(GUIDE).$*.sgml && mv *dvi ../out/$*/dvi
	cp src/$(GUIDE)-installconfig-config-webmin-loginscreen.eps out/$*/dvi/
	cp src/$(GUIDE)-networkbasics-protocols-x-flow.eps out/$*/dvi/
pdf-%: ps-% out/%/pdf
	ps2pdf out/$*/ps/$(GUIDE).$*.ps out/$*/pdf/$(GUIDE).$*.pdf
ps-%: out/%/ps
	cd src && sgml2latex -o ps -p a4 -l $* $(GUIDE).$*.sgml && mv $(GUIDE).$*.ps ../out/$*/ps
ps-gz-%: ps-% out/%/ps
	cd out/$*/ps && gzip -c $(GUIDE).$*.ps > $(GUIDE).$*.ps.gz
sgml-%: out/%/sgml
	cd src && cp $(GUIDE).$*.sgml ../out/$*/sgml

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

# -all targets. They depend on all language specific targets of the same type,
# i. e. if you want to build html files of all languages, type "make html-all".
html-all: $(foreach LANG,$(LANGUAGES),html-$(LANG))
dvi-all: $(foreach LANG,$(LANGUAGES),dvi-$(LANG))
pdf-all: $(foreach LANG,$(LANGUAGES),pdf-$(LANG))
ps-all: $(foreach LANG,$(LANGUAGES),ps-$(LANG))
ps-gz-all: $(foreach LANG,$(LANGUAGES),ps-gz-$(LANG))
sgml-all: $(foreach LANG,$(LANGUAGES),sgml-$(LANG))

all: html-all dvi-all pdf-all ps-all ps-gz-all sgml-all

clean-%:
	rm -rf out/$*

clean-all: $(foreach LANG,$(LANGUAGES),clean-$(LANG))

clean: clean-all

.PHONY: all clean clean-all html-all dvi-all pdf-all ps-all ps-gz-all sgml-all
