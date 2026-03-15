
MAKEFLAGS := -j 1

VERSION := $(shell head -n 1 ../CHANGES)
MAJOR   := $(firstword $(subst ., ,$(VERSION)))

export NAME VERSION MAJOR

LANGS = $(patsubst %/,%,$(wildcard */))

.PHONY: all clean install uninstall test

all clean install uninstall test:
	for dir in $(LANGS); do \
		if $(MAKE) $(MAKE_FLAGS) -C $$dir -f Makefile-swig $@; then \
		    true; \
		else \
		    exit 1; \
		fi; \
	done

