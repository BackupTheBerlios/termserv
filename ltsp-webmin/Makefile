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
PACKAGE = ltsp-webmin

ifndef $(WEBMINDIR)
    export WEBMINDIR=$(DESTDIR)/usr/share/webmin
endif

# webmin module package
wbm:
	@echo Building webmin module package ../$(PACKAGE)-$(VERSION).wbm
	@test -d tmp || mkdir tmp
	$(MAKE) install WEBMINDIR=tmp
	@(cd tmp && tar -cf ../../$(PACKAGE)-$(VERSION).wbm ltsp)

# debian package
deb: tgz
	cd tmp; $(FAKEROOT) dpkg-source -b $(PACKAGE)-$(VERSION) ""; mv *.dsc *.gz ../../
	$(FAKEROOT) debian/rules binary

# source package
tgz: clean deb-clean
	@echo Building source package ../$(PACKAGE)-$(VERSION).tar.gz
	@mkdir -p tmp/$(PACKAGE)-$(VERSION)
	@find . ! \( -name "tmp" -o -path '*tmp/*' -o -name ".cvsignore" -o -path '*CVS/*' -o -name "CVS" -a -type d \) -print | cpio -pmud --quiet tmp/$(PACKAGE)-$(VERSION)
	@(cd tmp && tar -czf ../../$(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION))

install:
# install all files under the ltsp directory, but ignore all CVS subdirs
# does anymody know a more elegant way? 
	@find ltsp ! \( -name ".cvsignore" -o -path '*CVS/*' -o -name "CVS" -a -type d \) -print | cpio -pmud --quiet $(WEBMINDIR)
# make sure the permissions are right
	@find $(WEBMINDIR) -name "*.gif" -exec chmod -x {} \;
	@find $(WEBMINDIR) -name "lang/*" -exec chmod -x {} \;
	@find $(WEBMINDIR) -name "pt" -exec chmod -x {} \;
	@find $(WEBMINDIR) -name "*lib.pl" -exec chmod -x {} \;
	@find $(WEBMINDIR) -name "*.java" -exec chmod -x {} \;
	@find $(WEBMINDIR) -name "mime.types" -exec chmod -x {} \;
	@find $(WEBMINDIR) -name "config-*" -exec chmod -x {} \;
	@find $(WEBMINDIR) -name "*.cgi" -exec chmod +x {} \;

clean:
	rm -rf tmp

deb-clean:
	$(FAKEROOT) debian/rules clean

.PHONY: clean deb deb-clean install tgz wbm
