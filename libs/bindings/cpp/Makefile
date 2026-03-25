NAME = postscriptbarcode

CXX ?= g++
CXXFLAGS = -std=c++17 -g -O2 -Wall -Wextra -pedantic -Werror -MMD -I. -I../../c

TEST = $(NAME)_test
EXAMPLE = example

LDFLAGS = -L../../c
LDLIBS = -l$(NAME)

PREFIX = /usr/local

.PHONY: all test clean install uninstall

all: $(EXAMPLE)

$(EXAMPLE): example.cpp $(NAME).hpp
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS) $(LDLIBS)

$(TEST): $(NAME)_test.cpp $(NAME).hpp ../../c/acutest.h
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS) $(LDLIBS)

test: $(TEST)
	LD_LIBRARY_PATH=../../c:$(LD_LIBRARY_PATH) ./$(TEST)

install: $(NAME).hpp
	install -d $(DESTDIR)$(PREFIX)/include
	install -m 0644 $(NAME).hpp $(DESTDIR)$(PREFIX)/include

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/include/$(NAME).hpp

clean:
	$(RM) $(EXAMPLE) $(TEST) *.o *.d test_barcode_cpp.ps

-include *.d
