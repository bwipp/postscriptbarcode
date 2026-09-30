NAME = postscriptbarcode

LUAJIT ?= luajit

PREFIX = /usr/local
LUADIR = $(PREFIX)/share/lua/5.1

.PHONY: all test clean install uninstall

all:

test:
	LD_LIBRARY_PATH=../../c:$(LD_LIBRARY_PATH) DYLD_LIBRARY_PATH=../../c:$(DYLD_LIBRARY_PATH) \
		$(LUAJIT) $(NAME)_test.lua

install: $(NAME).lua
	install -d $(DESTDIR)$(LUADIR)
	install -m 0644 $(NAME).lua $(DESTDIR)$(LUADIR)

uninstall:
	$(RM) $(DESTDIR)$(LUADIR)/$(NAME).lua

clean:
	$(RM) test_barcode_lua.ps
