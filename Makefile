PROGNAME  ?= serpent
PREFIX    ?= /.local
BINDIR    ?= $(PREFIX)/bin
LIBDIR    ?= $(PREFIX)/lib/$(PROGNAME)
SHAREDIR  ?= $(PREFIX)/share/$(PROGNAME)
RESDIR    ?= $(SHAREDIR)/res
LICENSE   ?= $(SHAREDIR)/license

.PHONY: install
install:src/$(PROGNAME)
	install -d $(BINDIR)
	install -m755 src/$(PROGNAME) $(BINDIR)/$(PROGNAME)
	install -Dm644 src/lib/*.* -t $(LIBDIR)
	install -Dm644 res/*.*  -t $(RESDIR)
	install -Dm644 LICENSE -t $(LICENSE)
	rm src/$(PROGNAME)

.PHONY: uninstall
uninstall:
	rm $(BINDIR)/$(PROGNAME)
	rm -rf $(LIBDIR)/$(PROGNAME)
	rm -rf $(SHAREDIR)/$(PROGNAME)