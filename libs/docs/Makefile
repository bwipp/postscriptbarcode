NAME = postscriptbarcode

MAJOR   := $(shell head -n 1 ../SOVERSION)
MINOR   := $(shell head -n 1 ../../CHANGES | tr -d '-')
VERSION := $(MAJOR).$(MINOR)

.PHONY: default all doc clean

default: doc
all: default

doc:
	PROJECT_NUMBER=$(VERSION) doxygen
	cat rmfiles.txt | while read FILE; do rm $$FILE; done

clean:
	$(RM) html/*

