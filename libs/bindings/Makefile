LANGS = $(patsubst %/,%,$(wildcard */))

.PHONY: all clean install uninstall

all clean install uninstall:
	for dir in $(LANGS); do \
		if $(MAKE) $(MAKE_FLAGS) -C $$dir -f Makefile-swig $@; then \
		    true; \
		else \
		    exit 1; \
		fi; \
	done

