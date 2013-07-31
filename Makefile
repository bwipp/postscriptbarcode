# Barcode Writer in Pure PostScript
# http://www.terryburton.co.uk/barcodewriter/
#
# Copyright (c) 2004-2013 Terry Burton
#
# $Id$

SRCDIR = src
DSTDIR = build

.PHONY : all clean monolithic monolithic_package resource packaged_resource

VERSION_FILE=$(SRCDIR)/VERSION
VERSION:=$(shell head -n 1 $(VERSION_FILE))

SOURCES:=$(wildcard $(SRCDIR)/*.ps)
TARGETS:=$(basename $(notdir $(SOURCES)))
TARGETS:=$(filter-out preamble, $(TARGETS))

RESDIR = $(DSTDIR)/resource
TARGETS_RES:=$(addprefix $(RESDIR)/Resource/uk.co.terryburton.bwipp/,$(TARGETS))
TARGETS_RES+=$(RESDIR)/Resource/Category/uk.co.terryburton.bwipp
TARGETS_RES+=$(RESDIR)/Resource/uk.co.terryburton.bwipp.upr
TARGETS_RES+=$(RESDIR)/README
TARGETS_RES+=$(RESDIR)/sample.ps
cleanlist += $(TARGETS_RES)

PACKAGEDIR = $(DSTDIR)/packaged_resource
TARGETS_PACKAGE:=$(addprefix $(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp/,$(TARGETS))
TARGETS_PACKAGE+=$(PACKAGEDIR)/Resource/Category/uk.co.terryburton.bwipp
TARGETS_PACKAGE+=$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp.upr
TARGETS_PACKAGE+=$(PACKAGEDIR)/README
TARGETS_PACKAGE+=$(PACKAGEDIR)/sample.ps
cleanlist += $(TARGETS_PACKAGE)

TARGET_DIRS = $(RESDIR) $(PACKAGEDIR)

MONOLITHIC_FILE = $(DSTDIR)/monolithic/barcode.ps
MONOLITHIC_FILE_WITH_SAMPLE = $(DSTDIR)/monolithic/barcode_with_sample.ps
MONOLITHIC_PACKAGE_FILE = $(DSTDIR)/monolithic_package/barcode.ps
MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE = $(DSTDIR)/monolithic_package/barcode_with_sample.ps
cleanlist += $(MONOLITHIC_FILE) $(MONOLITHIC_FILE_WITH_SAMPLE) $(MONOLITHIC_PACKAGE_FILE) $(MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE)

RELEASEDIR := $(DSTDIR)/release
RELEASE_RESOURCE_TARBALL := $(RELEASEDIR)/postscriptbarcode-resource-$(VERSION).tgz
RELEASE_PACKAGED_RESOURCE_TARBALL := $(RELEASEDIR)/postscriptbarcode-packaged-resource-$(VERSION).tgz
RELEASE_MONOLITHIC_TARBALL := $(RELEASEDIR)/postscriptbarcode-monolithic-$(VERSION).tgz
RELEASE_MONOLITHIC_PACKAGE_TARBALL := $(RELEASEDIR)/postscriptbarcode-monolithic-package-$(VERSION).tgz

all: resource packaged_resource monolithic monolithic_package

resource: $(TARGETS_RES)

packaged_resource: $(TARGETS_PACKAGE)

$(SRCDIR)/%.d: $(SRCDIR)/%.ps
	build/make_deps $< $(addsuffix /Resource,$(TARGET_DIRS)) >$@
cleanlist += ${SOURCES:.ps=.d}

ifneq "$(MAKECMDGOALS)" "clean"
-include ${SOURCES:.ps=.d}
endif

$(RESDIR)/Resource/uk.co.terryburton.bwipp/%: $(SRCDIR)/%.ps src/ps.head $(VERSION_FILE)
	build/make_resource $< $@

$(RESDIR)/Resource/Category/uk.co.terryburton.bwipp: $(SRCDIR)/preamble.ps src/ps.head $(VERSION_FILE)
	build/make_resource $< $@

$(RESDIR)/Resource/uk.co.terryburton.bwipp.upr: src/uk.co.terryburton.bwipp.upr
	cp $< $@
$(RESDIR)/README: src/README.resource
	cp $< $@
$(RESDIR)/sample.ps: src/sample
	cp $< $@

$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp/%: $(SRCDIR)/%.ps src/ps.head $(VERSION_FILE)
	build/make_packaged_resource $< $@

$(PACKAGEDIR)/Resource/Category/uk.co.terryburton.bwipp: $(SRCDIR)/preamble.ps src/ps.head $(VERSION_FILE)
	build/make_packaged_resource $< $@

$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp.upr: src/uk.co.terryburton.bwipp.upr
	cp $< $@
$(PACKAGEDIR)/README: src/README.resource
	cp $< $@
$(PACKAGEDIR)/sample.ps: src/sample
	cp $< $@

monolithic: $(MONOLITHIC_FILE) $(MONOLITHIC_FILE_WITH_SAMPLE)

$(MONOLITHIC_FILE): $(SOURCES) src/ps.head $(VERSION_FILE)
	build/make_monolithic >$@

$(MONOLITHIC_FILE_WITH_SAMPLE): $(MONOLITHIC_FILE) src/sample
	cat $(MONOLITHIC_FILE) src/sample > $@

monolithic_package: $(MONOLITHIC_PACKAGE_FILE) $(MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE)

$(MONOLITHIC_PACKAGE_FILE): $(TARGETS_PACKAGE) src/ps.head $(VERSION_FILE)
	build/make_monolithic $(PACKAGEDIR)/Resource >$@

$(MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE): $(MONOLITHIC_PACKAGE_FILE) src/sample $(VERSION_FILE)
	cat $(MONOLITHIC_PACKAGE_FILE) src/sample > $@

release: $(RELEASE_RESOURCE_TARBALL) $(RELEASE_PACKAGED_RESOURCE_TARBALL) $(RELEASE_MONOLITHIC_TARBALL) $(RELEASE_MONOLITHIC_PACKAGE_TARBALL)

define TARBALL
  tar --exclude-vcs --numeric-owner --owner=0 --group=0 --transform='s,^build/,postscriptbarcode-$(VERSION)/,' -czf $@
endef

$(RELEASE_RESOURCE_TARBALL): $(TARGETS_RES) $(VERSION_FILE)
	$(TARBALL) build/resource/

$(RELEASE_PACKAGED_RESOURCE_TARBALL): $(TARGETS_PACKAGE) $(VERSION_FILE)
	$(TARBALL) build/packaged_resource/

$(RELEASE_MONOLITHIC_TARBALL): $(MONOLITHIC_FILE) $(VERSION_FILE)
	$(TARBALL) build/monolithic/

$(RELEASE_MONOLITHIC_PACKAGE_TARBALL): $(MONOLITHIC_PACKAGE_FILE) $(VERSION_FILE)
	$(TARBALL) build/monolithic_package/

clean:
	$(RM) $(cleanlist)

