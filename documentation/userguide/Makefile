#!/usr/bin/make -f

GUIDE = userguide

html-de:
	cd src && sgml2html -l de -s 2 $(GUIDE).de.sgml && mv *html ../out/de/html
dvi-de:
	cd src && sgml2latex -p a4 -l de $(GUIDE).de.sgml && mv *dvi ../out/de/dvi
ps-de:
	cd src && sgml2latex -o ps -p a4 -l de $(GUIDE).de.sgml && mv $(GUIDE).de.ps ../out/de/ps
ps-gz-de: ps-de
	cd out/de/ps && gzip -c $(GUIDE).de.ps > $(GUIDE).de.ps.gz
sgml-de:
	cd src && cp $(GUIDE).de.sgml ../out/de/sgml

html-all: html-de
dvi-all: dvi-de
ps-all: ps-de
ps-gz-all: ps-gz-de
sgml-all: sgml-de

all: html-all dvi-all ps-all ps-gz-all sgml-all

clean-de:
	rm out/de/html/*
	rm out/de/dvi/*
	rm out/de/ps/*
	rm out/de/sgml/*

clean-all: clean-de

clean: clean-all

# .PHONY: all clean deb deb-clean install rpm tgz
