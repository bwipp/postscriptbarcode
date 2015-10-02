NAME = postscriptbarcode

MAJOR   := $(shell head -n 1 ../SOVERSION)
MINOR   := $(shell head -n 1 ../../CHANGES | tr -d '-')
VERSION := $(MAJOR).$(MINOR)

CFLAGS = -g -O2 -fPIC -Wall -Wextra -Wconversion -Wsign-conversion -Wformat -Wformat-security -Werror -pedantic
LDLIBS = -lc
LDFLAGS = -shared -Wl,-soname,lib$(NAME).so.$(MAJOR) -Wl,-Bsymbolic-functions -Wl,-z,relro

PREFIX = /usr/local
LIBDIR = $(PREFIX)/lib

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
	install -d $(DESTDIR)$(LIBDIR)
	install -m 0644 lib$(NAME).so.$(VERSION) $(DESTDIR)$(LIBDIR)
	ln -srf $(DESTDIR)$(LIBDIR)/lib$(NAME).so.$(VERSION) $(DESTDIR)$(LIBDIR)/lib$(NAME).so
	ln -srf $(DESTDIR)$(LIBDIR)/lib$(NAME).so.$(VERSION) $(DESTDIR)$(LIBDIR)/lib$(NAME).so.$(MAJOR)
	install -m 0644 lib$(NAME).a $(DESTDIR)$(LIBDIR)
	-ldconfig

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).h
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so*
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).a
	-ldconfig

