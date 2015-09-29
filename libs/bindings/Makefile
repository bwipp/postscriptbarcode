VERSION := $(shell head -n 1 ../CHANGES)
VERSION := $(subst ., ,$(VERSION))
MAJOR   := $(word 1, $(VERSION))
MINOR   := $(word 2, $(VERSION))
VERSION := $(MAJOR).$(MINOR)

export NAME VERSION MAJOR MINOR

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

