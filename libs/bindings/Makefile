
MAKEFLAGS := -j 1

VERSION := $(shell head -n 1 ../CHANGES)
MAJOR   := $(firstword $(subst ., ,$(VERSION)))

export NAME VERSION MAJOR

LANGS = $(patsubst %/,%,$(wildcard */))

.PHONY: all clean install uninstall test

all clean install uninstall test:
	for dir in $(LANGS); do \
		if [ -f $$dir/Makefile-swig ]; then \
			mf=Makefile-swig; \
		else \
			mf=Makefile; \
		fi; \
		if $(MAKE) $(MAKE_FLAGS) -C $$dir -f $$mf $@; then \
		    true; \
		else \
		    exit 1; \
		fi; \
	done

