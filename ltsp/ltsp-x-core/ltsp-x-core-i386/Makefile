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

all:
# need to do this because install.sh would be treated specially by debian/rules
	if test -f install.sh -a ! -f install-orig.sh; then $(MV) install.sh install-orig.sh; fi
	$(CP) install-orig.sh inst.sh
	patch -p0 < debian/diffs/inst.sh.diff
# need to do this, because otherwise a debian/rules binary would not work
#	if ! test -f install.sh; then touch install.sh; fi

install:
	./inst.sh

clean:
#see above (target all)
	if test -f install-orig.sh; then $(MV) install-orig.sh install.sh; fi
	$(RM) inst.sh

.PHONY: all clean install
