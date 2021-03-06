#!/usr/bin/make -f

# Get the version from the debian changelog.
# Reason: Only define the version at one place.
VERSION = ${shell head -1 debian/changelog | sed 's/.*(\([^-]*\)-.*/\1/'}

# Check wether the fakeroot program is available. With fakeroot, non root
# users can build the deb.
FAKEROOT = ${shell which fakeroot > /dev/null 2>&1 && echo fakeroot}

# The name of this package:
PACKAGE = termserv-doc

all:
	cd userguide && $(MAKE) all

# debian package
deb: tgz
	cd tmp; $(FAKEROOT) dpkg-source -b $(PACKAGE)-$(VERSION) ""; mv *.dsc *.gz ../../
	$(FAKEROOT) debian/rules binary

# rpm specfile
$(PACKAGE).spec: $(PACKAGE).spec.in
	sed s/_VERSION_/$(VERSION)/g < $< > $@

# rpm package
rpm: tgz
	rpm -ta ../$(PACKAGE)-$(VERSION).tar.gz

# source package
tgz: clean deb-clean $(PACKAGE).spec
	@echo Building source package ../$(PACKAGE)-$(VERSION).tar.gz
	@mkdir -p tmp/$(PACKAGE)-$(VERSION)
	@find . ! \( -name "tmp" -o -path '*tmp/*' -o -name ".cvsignore" -o -path '*CVS/*' -o -name "CVS" -a -type d \) -print | cpio -pmud --quiet tmp/$(PACKAGE)-$(VERSION)
	@(cd tmp && tar -czf ../../$(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION))

install:

clean:
	rm -rf tmp
	rm -f $(PACKAGE).spec
	cd userguide && $(MAKE) clean
	rm -rf userguide/out

deb-clean:
	$(FAKEROOT) debian/rules clean

.PHONY: all clean deb deb-clean install rpm tgz
