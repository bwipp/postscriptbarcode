NAME = postscriptbarcode

VERSION := $(shell head -n 1 ../CHANGES)

.PHONY: default all doc clean

default: doc
all: default

doc:
	PROJECT_NUMBER=$(VERSION) doxygen
	cat rmfiles.txt | while read FILE; do rm $$FILE; done

clean:
	$(RM) html/*

