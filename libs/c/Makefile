CFLAGS = -g -O2 -fPIC -Wall -Wextra -Wconversion -Wsign-conversion -Wformat -Wformat-security -Werror -pedantic
LDLIBS = -lc
LDFLAGS = -shared -Wl,-soname,lib$(NAME).so.$(MAJOR)

MAJOR = 0
MINOR = 1
NAME = postscriptbarcode
VERSION := $(MAJOR).$(MINOR)

.PHONY: default all clean

default: lib
all: default test

lib: lib$(NAME).so

lib$(NAME).so: lib$(NAME).so.$(VERSION)
	ldconfig -v -n .
	ln -s $< $@ 

lib$(NAME).so.$(VERSION): $(NAME).o
	$(CC) $(LDFLAGS) $(LDLIBS) $^ -o $@

test: $(NAME)_test
	LD_LIBRARY_PATH=. ./$(NAME)_test

$(NAME)_test: lib$(NAME).so $(NAME)_test.c
	$(CC) $(NAME)_test.c -o $@ -L. -l$(NAME)

clean:
	$(RM) $(NAME)_test *.o *.so*

