# Barcode Writer in Pure PostScript
# http://www.terryburton.co.uk/barcodewriter/
#
# Copyright (c) 2004-2013 Terry Burton
#
# $Id$

SRCDIR = src
DSTDIR = build

VERSION_FILE=$(SRCDIR)/VERSION
VERSION:=$(shell head -n 1 $(VERSION_FILE))

SOURCES:=$(wildcard $(SRCDIR)/*.ps)
TARGETS:=$(basename $(notdir $(SOURCES)))
TARGETS:=$(filter-out preamble, $(TARGETS))

UPR_FILE = src/uk.co.terryburton.bwipp.upr

RESDIR = $(DSTDIR)/resource
TARGETS_RES:=$(addprefix $(RESDIR)/Resource/uk.co.terryburton.bwipp/,$(TARGETS))
TARGETS_RES+=$(RESDIR)/Resource/Category/uk.co.terryburton.bwipp
TARGETS_RES+=$(RESDIR)/Resource/uk.co.terryburton.bwipp.upr
TARGETS_RES+=$(RESDIR)/README
TARGETS_RES+=$(RESDIR)/LICENSE
TARGETS_RES+=$(RESDIR)/CHANGES
TARGETS_RES+=$(RESDIR)/sample.ps
cleanlist += $(TARGETS_RES)

PACKAGEDIR = $(DSTDIR)/packaged_resource
TARGETS_PACKAGE:=$(addprefix $(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp/,$(TARGETS))
TARGETS_PACKAGE+=$(PACKAGEDIR)/Resource/Category/uk.co.terryburton.bwipp
TARGETS_PACKAGE+=$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp.upr
TARGETS_PACKAGE+=$(PACKAGEDIR)/README
TARGETS_PACKAGE+=$(PACKAGEDIR)/LICENSE
TARGETS_PACKAGE+=$(PACKAGEDIR)/CHANGES
TARGETS_PACKAGE+=$(PACKAGEDIR)/sample.ps
cleanlist += $(TARGETS_PACKAGE)

MONOLITHIC_DIR = $(DSTDIR)/monolithic
MONOLITHIC_FILE = $(MONOLITHIC_DIR)/barcode.ps
MONOLITHIC_FILE_WITH_SAMPLE = $(MONOLITHIC_DIR)/barcode_with_sample.ps
TARGETS_MONOLITHIC:=$(MONOLITHIC_FILE) $(MONOLITHIC_FILE_WITH_SAMPLE)
TARGETS_MONOLITHIC+=$(MONOLITHIC_DIR)/README
TARGETS_MONOLITHIC+=$(MONOLITHIC_DIR)/LICENSE
TARGETS_MONOLITHIC+=$(MONOLITHIC_DIR)/CHANGES
cleanlist += $(TARGETS_MONOLITHIC)

MONOLITHIC_PACKAGE_DIR = $(DSTDIR)/monolithic_package
MONOLITHIC_PACKAGE_FILE = $(MONOLITHIC_PACKAGE_DIR)/barcode.ps
MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE = $(MONOLITHIC_PACKAGE_DIR)/barcode_with_sample.ps
TARGETS_MONOLITHIC_PACKAGE:=$(MONOLITHIC_PACKAGE_FILE) $(MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE)
TARGETS_MONOLITHIC_PACKAGE+=$(MONOLITHIC_PACKAGE_DIR)/README
TARGETS_MONOLITHIC_PACKAGE+=$(MONOLITHIC_PACKAGE_DIR)/LICENSE
TARGETS_MONOLITHIC_PACKAGE+=$(MONOLITHIC_PACKAGE_DIR)/CHANGES
cleanlist += $(TARGETS_MONOLITHIC_PACKAGE)

RELEASEDIR := $(DSTDIR)/release
RELEASE_RESOURCE_TARBALL := $(RELEASEDIR)/postscriptbarcode-resource-$(VERSION).tgz
RELEASE_PACKAGED_RESOURCE_TARBALL := $(RELEASEDIR)/postscriptbarcode-packaged-resource-$(VERSION).tgz
RELEASE_MONOLITHIC_TARBALL := $(RELEASEDIR)/postscriptbarcode-monolithic-$(VERSION).tgz
RELEASE_MONOLITHIC_PACKAGE_TARBALL := $(RELEASEDIR)/postscriptbarcode-monolithic-package-$(VERSION).tgz

RELEASE_RESOURCE_ZIPFILE := $(RELEASEDIR)/postscriptbarcode-resource-$(VERSION).zip
RELEASE_PACKAGED_RESOURCE_ZIPFILE := $(RELEASEDIR)/postscriptbarcode-packaged-resource-$(VERSION).zip
RELEASE_MONOLITHIC_ZIPFILE := $(RELEASEDIR)/postscriptbarcode-monolithic-$(VERSION).zip
RELEASE_MONOLITHIC_PACKAGE_ZIPFILE := $(RELEASEDIR)/postscriptbarcode-monolithic-package-$(VERSION).zip

RELEASE_SOURCE_TARBALL := $(RELEASEDIR)/postscriptbarcode-source-$(VERSION).tgz

RELEASEFILES:=$(RELEASE_RESOURCE_TARBALL) $(RELEASE_PACKAGED_RESOURCE_TARBALL) $(RELEASE_MONOLITHIC_TARBALL) $(RELEASE_MONOLITHIC_PACKAGE_TARBALL)
RELEASEFILES+=$(RELEASE_RESOURCE_ZIPFILE) $(RELEASE_PACKAGED_RESOURCE_ZIPFILE) $(RELEASE_MONOLITHIC_ZIPFILE) $(RELEASE_MONOLITHIC_PACKAGE_ZIPFILE)
RELEASEFILES+=$(RELEASE_SOURCE_TARBALL)

#------------------------------------------------------------

.PHONY : all clean resource packaged_resource monolithic monolithic_package release

all: resource packaged_resource monolithic monolithic_package

clean:
	$(RM) $(cleanlist)

$(SRCDIR)/%.d: $(SRCDIR)/%.ps $(UPR_FILE)
	build/make_deps $< $(addsuffix /Resource,$(RESDIR) $(PACKAGEDIR)) >$@
cleanlist += ${SOURCES:.ps=.d}

ifneq "$(MAKECMDGOALS)" "clean"
-include ${SOURCES:.ps=.d}
endif

#------------------------------------------------------------

resource: $(TARGETS_RES)

$(RESDIR)/Resource/uk.co.terryburton.bwipp/%: $(SRCDIR)/%.ps src/ps.head $(VERSION_FILE)
	build/make_resource $< $@

$(RESDIR)/Resource/Category/uk.co.terryburton.bwipp: $(SRCDIR)/preamble.ps src/ps.head $(VERSION_FILE)
	build/make_resource $< $@

$(RESDIR)/Resource/uk.co.terryburton.bwipp.upr: $(UPR_FILE)
	cp $< $@
$(RESDIR)/README: src/README.resource
	cp $< $@
$(RESDIR)/sample.ps: src/sample
	cp $< $@
$(RESDIR)/LICENSE: LICENSE
	cp $< $@
$(RESDIR)/CHANGES: CHANGES
	cp $< $@

#------------------------------------------------------------

packaged_resource: $(TARGETS_PACKAGE)

$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp/%: $(SRCDIR)/%.ps src/ps.head $(VERSION_FILE)
	build/make_packaged_resource $< $@

$(PACKAGEDIR)/Resource/Category/uk.co.terryburton.bwipp: $(SRCDIR)/preamble.ps src/ps.head $(VERSION_FILE)
	build/make_packaged_resource $< $@

$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp.upr: $(UPR_FILE)
	cp $< $@
$(PACKAGEDIR)/README: src/README.resource
	cp $< $@
$(PACKAGEDIR)/sample.ps: src/sample
	cp $< $@
$(PACKAGEDIR)/LICENSE: LICENSE
	cp $< $@
$(PACKAGEDIR)/CHANGES: CHANGES
	cp $< $@

#------------------------------------------------------------

monolithic: $(TARGETS_MONOLITHIC)

$(MONOLITHIC_FILE): $(SOURCES) src/ps.head $(VERSION_FILE) $(UPR_FILE)
	build/make_monolithic >$@
$(MONOLITHIC_FILE_WITH_SAMPLE): $(MONOLITHIC_FILE) src/sample
	cat $(MONOLITHIC_FILE) src/sample > $@
$(MONOLITHIC_DIR)/README: README
	cp $< $@
$(MONOLITHIC_DIR)/LICENSE: LICENSE
	cp $< $@
$(MONOLITHIC_DIR)/CHANGES: CHANGES
	cp $< $@

#------------------------------------------------------------

monolithic_package: $(TARGETS_MONOLITHIC_PACKAGE)

$(MONOLITHIC_PACKAGE_FILE): $(TARGETS_PACKAGE) src/ps.head $(VERSION_FILE) $(UPR_FILE)
	build/make_monolithic $(PACKAGEDIR)/Resource >$@
$(MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE): $(MONOLITHIC_PACKAGE_FILE) src/sample $(VERSION_FILE)
	cat $(MONOLITHIC_PACKAGE_FILE) src/sample > $@
$(MONOLITHIC_PACKAGE_DIR)/README: README
	cp $< $@
$(MONOLITHIC_PACKAGE_DIR)/LICENSE: LICENSE
	cp $< $@
$(MONOLITHIC_PACKAGE_DIR)/CHANGES: CHANGES
	cp $< $@

#------------------------------------------------------------

release: $(RELEASEFILES)

define TARBALL
  tar --exclude-vcs --numeric-owner --owner=0 --group=0 --mtime=./$(VERSION_FILE) --transform='s,^build/,postscriptbarcode-$(VERSION)/,' -czf $@ $(1)
endef

define ZIPFILE
  $(RM) $@; FILE=`readlink -f $@` && cd $(1) && zip -q -X -r $$FILE .
endef

$(RELEASE_RESOURCE_TARBALL): $(TARGETS_RES) $(VERSION_FILE)
	$(call TARBALL,$(RESDIR))

$(RELEASE_RESOURCE_ZIPFILE): $(TARGETS_RES) $(VERSION_FILE)
	$(call ZIPFILE,$(RESDIR))

$(RELEASE_PACKAGED_RESOURCE_TARBALL): $(TARGETS_PACKAGE) $(VERSION_FILE)
	$(call TARBALL,$(PACKAGEDIR))

$(RELEASE_PACKAGED_RESOURCE_ZIPFILE): $(TARGETS_PACKAGE) $(VERSION_FILE)
	$(call ZIPFILE,$(PACKAGEDIR))

$(RELEASE_MONOLITHIC_TARBALL): $(TARGETS_MONOLITHIC) $(VERSION_FILE)
	$(call TARBALL,$(MONOLITHIC_DIR))

$(RELEASE_MONOLITHIC_ZIPFILE): $(TARGETS_MONOLITHIC) $(VERSION_FILE)
	$(call ZIPFILE,$(MONOLITHIC_DIR))

$(RELEASE_MONOLITHIC_PACKAGE_TARBALL): $(TARGETS_MONOLITHIC_PACKAGE) $(VERSION_FILE)
	$(call TARBALL,$(MONOLITHIC_PACKAGE_DIR))

$(RELEASE_MONOLITHIC_PACKAGE_ZIPFILE): $(TARGETS_MONOLITHIC_PACKAGE) $(VERSION_FILE)
	$(call ZIPFILE,$(MONOLITHIC_PACKAGE_DIR))

$(RELEASE_SOURCE_TARBALL): $(VERSION_FILE)
	tar --exclude-vcs --exclude=$(RELEASEDIR) $(addprefix --exclude=,$(cleanlist)) --numeric-owner --owner=0 --group=0 --mtime=./$(VERSION_FILE) --transform='s,^.,postscriptbarcode-$(VERSION),' -czf $@ .

