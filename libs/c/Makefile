NAME = postscriptbarcode

MAJOR   := $(shell head -n 1 ../SOVERSION)
MINOR   := $(shell head -n 1 ../../CHANGES | tr -d '-')
VERSION := $(MAJOR).$(MINOR)

ifeq ($(SANITIZE),yes)
CC=clang
SAN_LDFLAGS = -fuse-ld=lld
SAN_CFLAGS = -fsanitize=address,leak,undefined -fno-omit-frame-pointer -fno-optimize-sibling-calls -O1
SAN_ENV = ASAN_OPTIONS="symbolize=1 detect_leaks=1" LSAN_OPTIONS="fast_unwind_on_malloc=0:malloc_context_size=50" ASAN_SYMBOLIZER_PATH="$(shell which llvm-symbolizer)"
endif

# Leak detection is not supported on MacOS builds of LLVM
ifeq ($(SANITIZE),noleak)
CC=clang
SAN_LDFLAGS = -fuse-ld=lld
SAN_CFLAGS = -fsanitize=address,undefined -fno-omit-frame-pointer -fno-optimize-sibling-calls -O1
SAN_ENV = ASAN_OPTIONS="symbolize=1" LSAN_OPTIONS="fast_unwind_on_malloc=0:malloc_context_size=50" ASAN_SYMBOLIZER_PATH="$(shell which llvm-symbolizer)"
endif

ifneq ($(shell uname -s),Darwin)
LDFLAGS = -Wl,--as-needed -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now $(SAN_LDFLAGS)
LDFLAGS_SO = -shared -Wl,-soname,lib$(NAME).so.$(MAJOR)
CFLAGS_FORTIFY = -D_FORTIFY_SOURCE=2
else
LDFLAGS =
LDFLAGS_SO = -shared -Wl,-install_name,lib$(NAME).so.$(MAJOR)
CFLAGS_FORTIFY =
endif

LDLIBS = -lc
CFLAGS = -g -O2 $(CFLAGS_FORTIFY) -Wall -Wextra -Wconversion -Wformat -Wformat-security -Wdeclaration-after-statement -pedantic -Werror -MMD -fPIC $(SAN_CFLAGS)

TEST_SHARED = $(NAME)_test_shared
TEST_STATIC = $(NAME)_test_static

PREFIX = /usr/local
LIBDIR = $(PREFIX)/lib

.PHONY: default all clean lib libstatic libshared test install install-static install-shared uninstall

default: lib
all: default test

lib: libshared libstatic
libshared: lib$(NAME).so.$(VERSION) lib$(NAME).so lib$(NAME).so.$(MAJOR)
libstatic: lib$(NAME).a

lib$(NAME).so: lib$(NAME).so.$(VERSION) lib$(NAME).so.$(MAJOR)
	ln -sf $< $@

lib$(NAME).so.$(MAJOR): lib$(NAME).so.$(VERSION)
	ln -sf $< $@

lib$(NAME).so.$(VERSION): $(NAME).o
	$(CC) $(CFLAGS) $(LDFLAGS) $(LDFLAGS_SO) $(LDLIBS) $^ -o $@

lib$(NAME).a: $(NAME).o
	$(AR) cr $@ $^
	ranlib $@

$(NAME).o: $(NAME).c $(NAME).h $(NAME)_private.h
	$(CC) $(CFLAGS) -c -o $@ $<

$(TEST_SHARED): lib$(NAME).so $(NAME)_test.c
	$(CC) $(CFLAGS) $(NAME)_test.c -o $@ -L. -l$(NAME)

$(TEST_STATIC): $(NAME).o $(NAME)_test.c
	$(CC) $(CFLAGS) $(LDFLAGS) $(NAME).o $(NAME)_test.c -o $@

test: $(TEST_SHARED) $(TEST_STATIC)
	$(SAN_ENV) LD_LIBRARY_PATH=.:$$LD_LIBRARY_PATH ./$(TEST_SHARED)
	$(SAN_ENV) ./$(TEST_STATIC)

clean:
	$(RM) $(TEST_SHARED) $(TEST_STATIC) *.o *.so* *.a *.d

install: install-static install-shared

install-headers:
	install -d $(DESTDIR)$(PREFIX)/include
	install -m 0644 $(NAME).h $(DESTDIR)$(PREFIX)/include

install-static: libstatic install-headers
	install -d $(DESTDIR)$(LIBDIR)
	install -m 0644 lib$(NAME).a $(DESTDIR)$(LIBDIR)

install-shared: libshared install-headers
	install -d $(DESTDIR)$(LIBDIR)
	install -m 0644 lib$(NAME).so.$(VERSION) $(DESTDIR)$(LIBDIR)
	cd $(DESTDIR)$(LIBDIR) && ln -sf lib$(NAME).so.$(VERSION) lib$(NAME).so
	cd $(DESTDIR)$(LIBDIR) && ln -sf lib$(NAME).so.$(VERSION) lib$(NAME).so.$(MAJOR)
	-ldconfig

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).h
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).so*
	$(RM) $(DESTDIR)$(PREFIX)/lib/lib$(NAME).a
	-ldconfig
