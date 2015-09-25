NAME = postscriptbarcode

VERSION := $(shell head -n 1 ../CHANGES)
VERSION := $(subst ., ,$(VERSION))
MAJOR   := $(word 1, $(VERSION))
MINOR   := $(word 2, $(VERSION))
VERSION := $(MAJOR).$(MINOR)

CFLAGS = -g -O2 -fPIC -fstack-protector-strong -Wall -Wextra -Wconversion -Wsign-conversion -Wformat -Wformat-security -Werror -pedantic
LDLIBS = -lc
LDFLAGS = -shared -Wl,-soname,lib$(NAME).so.$(MAJOR) -Wl,-Bsymbolic-functions -Wl,-z,relro

PREFIX = /usr/local

.PHONY: default all clean lib libstatic libshared test install uninstall

default: lib
all: default test

lib: libshared libstatic
libshared: lib$(NAME).so.$(VERSION) lib$(NAME).so lib$(NAME).so.$(MAJOR)
libstatic: lib$(NAME).a

lib$(NAME).so: lib$(NAME).so.$(VERSION)
	ln -sf $< $@ 

lib$(NAME).so.$(MAJOR): lib$(NAME).so.$(VERSION)
	ln -sf $< $@ 

lib$(NAME).so.$(VERSION): $(NAME).o
	$(CC) $(LDFLAGS) $(LDLIBS) $^ -o $@

lib$(NAME).a: $(NAME).o
	$(AR) cr $@ $^
	ranlib $@

$(NAME).o: $(NAME).c $(NAME).h $(NAME)_private.h

test: $(NAME)_test
	LD_LIBRARY_PATH=.:$$LD_LIBRARY_PATH ./$(NAME)_test

$(NAME)_test: lib$(NAME).so $(NAME)_test.c
	$(CC) $(NAME)_test.c -o $@ -L. -l$(NAME)

clean:
	$(RM) $(NAME)_test *.o *.so* *.a

install: lib
	install -d $(DESTDIR)$(PREFIX)/include
	install -m 0644 $(NAME).h $(DESTDIR)$(PREFIX)/include
	install -d $(DESTDIR)$(PREFIX)/lib
	install -m 0644 lib$(NAME).so.$(VERSION) $(DESTDIR)$(PREFIX)/lib
	ln -srf $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so.$(VERSION) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so
	ln -srf $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so.$(VERSION) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so.$(MAJOR)
	install -m 0644 lib$(NAME).a $(DESTDIR)$(PREFIX)/lib
	-ldconfig

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).h
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so*
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).a
	-ldconfig

