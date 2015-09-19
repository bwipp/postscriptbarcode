NAME = postscriptbarcode

VERSION := $(shell head -n 1 ../CHANGES)
VERSION := $(subst ., ,$(VERSION))
MAJOR   := $(word 1, $(VERSION))
MINOR   := $(word 2, $(VERSION))
VERSION := $(MAJOR).$(MINOR)

CFLAGS = -g -O2 -fPIC -Wall -Wextra -Wconversion -Wsign-conversion -Wformat -Wformat-security -Werror -pedantic
LDLIBS = -lc
LDFLAGS = -shared -Wl,-soname,lib$(NAME).so.$(MAJOR)

PREFIX = /usr/local

.PHONY: default all clean lib test install uninstall

default: lib
all: default test

lib: lib$(NAME).so lib$(NAME).so.$(MAJOR)

lib$(NAME).so: lib$(NAME).so.$(VERSION)
	ln -sf $< $@ 

lib$(NAME).so.$(MAJOR): lib$(NAME).so.$(VERSION)
	ln -sf $< $@ 

lib$(NAME).so.$(VERSION): $(NAME).o
	$(CC) $(LDFLAGS) $(LDLIBS) $^ -o $@

$(NAME).o: $(NAME).c $(NAME).h $(NAME)_private.h

test: $(NAME)_test
	LD_LIBRARY_PATH=. ./$(NAME)_test

$(NAME)_test: lib$(NAME).so $(NAME)_test.c
	$(CC) $(NAME)_test.c -o $@ -L. -l$(NAME)

clean:
	$(RM) $(NAME)_test *.o *.so*

install: lib
	install -d $(DESTDIR)$(PREFIX)/lib
	install lib$(NAME).so.$(VERSION) $(DESTDIR)$(PREFIX)/lib
	ln -srf $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so.$(VERSION) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so
	ln -srf $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so.$(VERSION) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so.$(MAJOR)
	install -d $(DESTDIR)$(PREFIX)/include
	install $(NAME).h $(DESTDIR)$(PREFIX)/include

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so*
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).h

