ifndef $(INSTALL)
INSTALL = /usr/bin/install
endif
ifndef $(MAKE)
MAKE = make
endif
LN = ln -sf
RM = rm
CD = cd
CP = cp
MV = mv

include CONFIG
REAL_ROOT_DIR = $(subst $(DESTDIR),,$(ROOT_DIR))

all:
# need to do this because install.sh would be treated specially by debian/rules
	if test -f install.sh -a ! -f install-orig.sh; then $(MV) install.sh install-orig.sh; fi
	$(CP) install-orig.sh create-templates.sh
	$(CP) install-orig.sh inst.sh
	patch -p0 < debian/diffs/create-templates.sh.diff
	patch -p0 < debian/diffs/inst.sh.diff
# need to do this, because otherwise a debian/rules binary would not work
#	if ! test -f install.sh; then touch install.sh; fi
	$(LN) debian.sh debian-sarge.sh

install:
	./inst.sh
	$(INSTALL) -d $(SCRIPT_DIR)
	$(INSTALL) create-templates.sh -m 755 $(SCRIPT_DIR)
	$(INSTALL) CONFIG -m 644 $(SCRIPT_DIR)
	$(INSTALL) install_functions.sh -m 644 $(SCRIPT_DIR)
	$(INSTALL) debian.sh -m 755 $(SCRIPT_DIR)
	for f in debian-*.sh; do $(LN) debian.sh $(SCRIPT_DIR)/$$f; done
	$(INSTALL) gdm-change.pl -m 755 $(SCRIPT_DIR)
	$(INSTALL) kdm-change.pl -m 755 $(SCRIPT_DIR)
	$(INSTALL) inetd.pl -m 755 $(SCRIPT_DIR)
	$(INSTALL) ltsp_initialize -m 755 $(TMPL_DIR)
	$(INSTALL) -d $(ROOT_DIR)/usr/lib
	$(INSTALL) -d $(ROOT_DIR)/usr/X11R6/bin
	$(LN) /tmp/var $(ROOT_DIR)/var
#	$(INSTALL) -d $(ROOT_DIR)/usr/X11R6/lib/X11/xserver
#	$(LN) /etc/X11/xserver/SecurityPolicy $(ROOT_DIR)/usr/X11R6/lib/X11/xserver/SecurityPolicy
	$(INSTALL) -d $(DESTDIR)/etc/ltsp
	$(LN) $(REAL_ROOT_DIR)/etc/lts.conf $(DESTDIR)/etc/ltsp/lts.conf

clean:
#see above (target all)
	if test -f install-orig.sh; then $(MV) install-orig.sh install.sh; fi
	$(RM) create-templates.sh
	$(RM) inst.sh
	$(RM) debian-sarge.sh

.PHONY: all clean install
