#!/usr/bin/make -f

# Caution! If neither DESTDIR nor WEBMINDIR is set, 'make install' installs
# under /usr/share/webmin, which may not be what you want.

# Get the version from the debian changelog.
# Reason: Only define the version at one place.
VERSION = ${shell head -1 debian/changelog | sed 's/.*(\([^-]*\)-.*/\1/'}

# Check wether the fakeroot program is available. With fakeroot, non root
# users can build the deb.
FAKEROOT = ${shell which fakeroot}

# The name of this package:
PACKAGE = task-termserv

# debian package
deb:
	$(FAKEROOT) debian/rules binary

# rpm specfile
$(PACKAGE).spec: $(PACKAGE).spec.in
	sed < $< s/_VERSION_/$(VERSION)/g > $@

# rpm package
rpm: tgz $(PACKAGE).spec
	rpm -ta ../$(PACKAGE)-$(VERSION).tar.gz

# source package
tgz: clean deb-clean task-termserv.spec
	@echo Building source package ../$(PACKAGE)-$(VERSION).tar.gz
	@mkdir -p tmp/$(PACKAGE)-$(VERSION)
	@find . ! \( -name "tmp" -o -path '*tmp/*' -o -name ".cvsignore" -o -path '*CVS/*' -o -name "CVS" -a -type d \) -print | cpio -pmud --quiet tmp/$(PACKAGE)-$(VERSION)
	@(cd tmp && tar -czf ../../$(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION))

install:

clean:
	rm -rf tmp
	rm -f $(PACKAGE).spec

deb-clean:
	$(FAKEROOT) debian/rules clean

.PHONY: clean deb deb-clean install rpm tgz wbm
