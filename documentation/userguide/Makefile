#!/usr/bin/make -f

GUIDE = userguide

html-de: out/de/html
	cd src && sgml2html -l de -s 2 $(GUIDE).de.sgml && mv *html ../out/de/html
dvi-de: out/de/dvi
	cd src && sgml2latex -o dvi -p a4 -l de $(GUIDE).de.sgml && mv *dvi ../out/de/dvi
ps-de: out/de/ps
	cd src && sgml2latex -o ps -p a4 -l de $(GUIDE).de.sgml && mv $(GUIDE).de.ps ../out/de/ps
ps-gz-de: ps-de out/de/ps
	cd out/de/ps && gzip -c $(GUIDE).de.ps > $(GUIDE).de.ps.gz
sgml-de: out/de/sgml
	cd src && cp $(GUIDE).de.sgml ../out/de/sgml

html-all: html-de
dvi-all: dvi-de
ps-all: ps-de
ps-gz-all: ps-gz-de
sgml-all: sgml-de

all: html-all dvi-all ps-all ps-gz-all sgml-all

out/de/dvi:
	mkdir -p $@
out/de/html:
	mkdir -p $@
out/de/ps:
	mkdir -p $@
out/de/sgml:
	mkdir -p $@

all: html-all dvi-all ps-all ps-gz-all sgml-all

clean-de:
	rm -f out/de/html/*
	rm -f out/de/dvi/*
	rm -f out/de/ps/*
	rm -f out/de/sgml/*

clean-all: clean-de

clean: clean-all

.PHONY: all clean clean-all clean-de html-all dvi-all ps-all ps-gz-all sgml-all
