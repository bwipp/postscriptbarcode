NAME = postscriptbarcode

VERSION := $(shell head -n 1 ../CHANGES)
VERSION := $(subst ., ,$(VERSION))
MAJOR   := $(word 1, $(VERSION))
MINOR   := $(word 2, $(VERSION))
VERSION := $(MAJOR).$(MINOR)

CFLAGS = -g -O2 -fPIC -Wall -Wextra -Wconversion -Wsign-conversion -Wformat -Wformat-security -Werror -pedantic
LDLIBS = -lc
LDFLAGS = -shared -Wl,-soname,lib$(NAME).so.$(MAJOR)

.PHONY: default all clean test

default: lib
all: default test

lib: lib$(NAME).so

lib$(NAME).so: lib$(NAME).so.$(VERSION)
	ldconfig -v -n .
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

