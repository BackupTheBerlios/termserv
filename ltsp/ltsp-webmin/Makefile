#!/usr/bin/make -f

# Caution! If neither DESTDIR nor WEBMINDIR is set, 'make install' installs
# under /usr/share/webmin, which may not be what you want.

# Get the version from the debian changelog.
# Reason: Only define the version at one place.
VERSION = ${shell head -1 debian/changelog | sed 's/.*(\([^-]*\)-.*/\1/'}

# Check wether the fakeroot program is available. With fakeroot, non root
# users can build the deb.
FAKEROOT = ${shell which fakeroot > /dev/null 2>&1 && echo fakeroot}

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

# rpm specfile
$(PACKAGE).spec: $(PACKAGE).spec.in
	sed s/_VERSION_/$(VERSION)/g < $< > $@

# rpm package
rpm: tgz
	rpm -ta ../$(PACKAGE)-$(VERSION).tar.gz

# source package
tgz: clean  deb-clean $(PACKAGE).spec
	@echo Building source package ../$(PACKAGE)-$(VERSION).tar.gz
	@mkdir -p tmp/$(PACKAGE)-$(VERSION)
	@find . ! \( -name "tmp" -o -path '*tmp/*' -o -name ".cvsignore" -o -path '*CVS/*' -o -name "CVS" -a -type d \) -print | cpio -pmud --quiet tmp/$(PACKAGE)-$(VERSION)
	@(cd tmp && tar -czf ../../$(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION))

install:
# install all files under the ltsp directory, but ignore all CVS subdirs
# does anymody know a more elegant way? 
	@find ltsp ! \( -name ".cvsignore" -o -path '*CVS/*' -o -name "CVS" -a -type d \) -print | cpio -pmud --quiet $(WEBMINDIR)
# make sure the permissions are right
	@find $(WEBMINDIR)/ltsp -name "*.gif" -exec chmod -x {} \;
	@find $(WEBMINDIR)/ltsp -name "lang/*" -exec chmod -x {} \;
	@find $(WEBMINDIR)/ltsp -name "pt" -exec chmod -x {} \;
	@find $(WEBMINDIR)/ltsp -name "*lib.pl" -exec chmod -x {} \;
	@find $(WEBMINDIR)/ltsp -name "*.java" -exec chmod -x {} \;
	@find $(WEBMINDIR)/ltsp -name "mime.types" -exec chmod -x {} \;
	@find $(WEBMINDIR)/ltsp -name "config-*" -exec chmod -x {} \;
	@find $(WEBMINDIR)/ltsp -name "*.cgi" -exec chmod +x {} \;

clean:
	rm -rf tmp files_not_in_cvs
	rm -f $(PACKAGE).spec

deb-clean:
	$(FAKEROOT) debian/rules clean

# The following is stolen from KDE (admin/Makefile.common)
cvs-clean:
	@if test ! -d CVS; then \
	  echo "You don't have a toplevel CVS directory."; \
	  echo "You most certainly didn't use cvs to get these sources."; \
	  echo "But this function depends on cvs's information."; \
	  exit 1 ;\
	fi;\
	pwd=`pwd` ;\
	dirs=`find . -type d | grep -v CVS | sed -e "s#^./##"` ;\
	for i in $$dirs; do \
	  if test ! -d "$$pwd/$$i/CVS"; then \
	    echo "D $$i" ;\
	    rm -rf "$$pwd/$$i"; \
	    continue; \
	  fi ;\
	  cd $$pwd/$$i ;\
	  for f in * .*; do \
	    if test ! -d "$$f"; then \
	      if grep "^/$$f/" CVS/Entries > /dev/null; then \
		a="b"; \
	      else \
	        echo "F $$i/$$f"; \
		rm -f "$$pwd/$$i/$$f"; \
	      fi; \
	    fi ; \
	  done; \
	done

# Build a list for checking in many new files
# This is based on cvs-clean
files_not_in_cvs: clean deb-clean
	@if test ! -d CVS; then \
	  echo "You don't have a toplevel CVS directory."; \
	  echo "You most certainly didn't use cvs to get these sources."; \
	  echo "But this function depends on cvs's information."; \
	  exit 1 ;\
	fi;\
	rm -f $@; \
	pwd=`pwd` ;\
	dirs=`find . -type d | grep -v CVS | sed -e "s#^./##"` ;\
	for i in $$dirs; do \
	  if test ! -d "$$pwd/$$i/CVS"; then \
	    echo "D $$i" ;\
	    echo "$$i" >> $$pwd/$@; \
	  fi ;\
	  cd $$pwd/$$i ;\
	  for f in * .*; do \
	    if test ! -d "$$f"; then \
	      if grep "^/$$f/" CVS/Entries > /dev/null 2>&1; then \
		a="b"; \
	      else \
	        echo "F $$i/$$f"; \
		echo "$$i/$$f" >> $$pwd/$@; \
	      fi; \
	    fi ; \
	  done; \
	done


.PHONY: clean cvs-clean deb deb-clean install rpm tgz wbm
