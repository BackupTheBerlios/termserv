ifndef $(INSTALL)
INSTALL = /usr/bin/install
endif
CP = cp
MV = mv
RM = rm -f

all:
# need to do this because install.sh would be treated specially by debian/rules
	if test -f install.sh -a ! -f install-orig.sh; then $(MV) install.sh install-orig.sh; fi
	$(CP) install-orig.sh inst.sh
	patch -p0 < debian/diffs/inst.sh.diff

install:
	mkdir -p $(DESTDIR)/tftpboot/lts/
	./inst.sh

clean:
#see above (target all)
	if test -f install-orig.sh; then $(MV) install-orig.sh install.sh; fi
	$(RM) inst.sh

.PHONY: all clean install
