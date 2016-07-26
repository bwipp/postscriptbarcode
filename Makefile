# Barcode Writer in Pure PostScript
# http://bwipp.terryburton.co.uk
#
# Copyright (c) 2004-2014 Terry Burton
#
# $Id$

SRCDIR = src
DOCDIR = docs
DSTDIR = build

CHANGES_FILE=CHANGES
VERSION:=$(shell head -n 1 $(CHANGES_FILE))

SOURCES:=$(wildcard $(SRCDIR)/*.ps)
DOCNAMES:=$(notdir $(wildcard $(DOCDIR)/*))

TARGETS:=$(basename $(notdir $(SOURCES)))
TARGETS:=$(filter-out preamble, $(TARGETS))

UPR_FILE = $(SRCDIR)/uk.co.terryburton.bwipp.upr

RESDIR = $(DSTDIR)/resource
RESMKDIRS:=$(RESDIR)
RESMKDIRS+=$(RESDIR)/Resource
RESMKDIRS+=$(RESDIR)/Resource/Category
RESMKDIRS+=$(RESDIR)/Resource/uk.co.terryburton.bwipp
RESMKDIRS+=$(RESDIR)/docs
RESMKDIRSTAMP:=$(RESDIR)/.dirstamp
TARGETS_RES:=$(addprefix $(RESDIR)/Resource/uk.co.terryburton.bwipp/,$(TARGETS))
TARGETS_RES+=$(RESDIR)/Resource/Category/uk.co.terryburton.bwipp
TARGETS_RES+=$(RESDIR)/Resource/uk.co.terryburton.bwipp.upr
TARGETS_RES+=$(RESDIR)/README
TARGETS_RES+=$(RESDIR)/LICENSE
TARGETS_RES+=$(RESDIR)/CHANGES
TARGETS_RES+=$(RESDIR)/sample.ps
TARGETS_RES+=$(addprefix $(RESDIR)/docs/,$(DOCNAMES))
cleanlist += $(TARGETS_RES) $(RESMKDIRSTAMP)

PACKAGEDIR = $(DSTDIR)/packaged_resource
PACKAGEMKDIRS:=$(PACKAGEDIR)
PACKAGEMKDIRS+=$(PACKAGEDIR)/Resource
PACKAGEMKDIRS+=$(PACKAGEDIR)/Resource/Category
PACKAGEMKDIRS+=$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp
PACKAGEMKDIRS+=$(PACKAGEDIR)/docs
PACKAGEMKDIRSTAMP:=$(PACKAGEDIR)/.dirstamp
TARGETS_PACKAGE:=$(addprefix $(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp/,$(TARGETS))
TARGETS_PACKAGE+=$(PACKAGEDIR)/Resource/Category/uk.co.terryburton.bwipp
TARGETS_PACKAGE+=$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp.upr
TARGETS_PACKAGE+=$(PACKAGEDIR)/README
TARGETS_PACKAGE+=$(PACKAGEDIR)/LICENSE
TARGETS_PACKAGE+=$(PACKAGEDIR)/CHANGES
TARGETS_PACKAGE+=$(PACKAGEDIR)/sample.ps
TARGETS_PACKAGE+=$(addprefix $(PACKAGEDIR)/docs/,$(DOCNAMES))
cleanlist += $(TARGETS_PACKAGE) $(PACKAGEMKDIRSTAMP)

MONOLITHIC_DIR = $(DSTDIR)/monolithic
MONOLITHIC_MKDIRS:=$(MONOLITHIC_DIR)
MONOLITHIC_MKDIRS+=$(MONOLITHIC_DIR)/docs
MONOLITHIC_MKDIRSTAMP:=$(MONOLITHIC_DIR)/.dirstamp
MONOLITHIC_FILE = $(MONOLITHIC_DIR)/barcode.ps
MONOLITHIC_FILE_WITH_SAMPLE = $(MONOLITHIC_DIR)/barcode_with_sample.ps
TARGETS_MONOLITHIC:=$(MONOLITHIC_FILE) $(MONOLITHIC_FILE_WITH_SAMPLE)
TARGETS_MONOLITHIC+=$(MONOLITHIC_DIR)/README
TARGETS_MONOLITHIC+=$(MONOLITHIC_DIR)/LICENSE
TARGETS_MONOLITHIC+=$(MONOLITHIC_DIR)/CHANGES
TARGETS_MONOLITHIC+=$(addprefix $(MONOLITHIC_DIR)/docs/,$(DOCNAMES))
cleanlist += $(TARGETS_MONOLITHIC) $(MONOLITHIC_MKDIRSTAMP)

MONOLITHIC_PACKAGE_DIR = $(DSTDIR)/monolithic_package
MONOLITHIC_PACKAGE_MKDIRS:=$(MONOLITHIC_PACKAGE_DIR)
MONOLITHIC_PACKAGE_MKDIRS+=$(MONOLITHIC_PACKAGE_DIR)/docs
MONOLITHIC_PACKAGE_MKDIRSTAMP:=$(MONOLITHIC_PACKAGE_DIR)/.dirstamp
MONOLITHIC_PACKAGE_FILE = $(MONOLITHIC_PACKAGE_DIR)/barcode.ps
MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE = $(MONOLITHIC_PACKAGE_DIR)/barcode_with_sample.ps
TARGETS_MONOLITHIC_PACKAGE:=$(MONOLITHIC_PACKAGE_FILE) $(MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE)
TARGETS_MONOLITHIC_PACKAGE+=$(MONOLITHIC_PACKAGE_DIR)/README
TARGETS_MONOLITHIC_PACKAGE+=$(MONOLITHIC_PACKAGE_DIR)/LICENSE
TARGETS_MONOLITHIC_PACKAGE+=$(MONOLITHIC_PACKAGE_DIR)/CHANGES
TARGETS_MONOLITHIC_PACKAGE+=$(addprefix $(MONOLITHIC_PACKAGE_DIR)/docs/,$(DOCNAMES))
cleanlist += $(TARGETS_MONOLITHIC_PACKAGE) $(MONOLITHIC_PACKAGE_MKDIRSTAMP)

STANDALONE_DIR = $(DSTDIR)/standalone
STANDALONE_MKDIRS:=$(STANDALONE_DIR)
STANDALONE_MKDIRSTAMP:=$(STANDALONE_DIR)/.dirstamp
TARGETS_STANDALONE:=$(addprefix $(STANDALONE_DIR)/,$(addsuffix .ps,$(TARGETS)))
cleanlist += $(TARGETS_STANDALONE) $(STANDALONE_MKDIRSTAMP)

STANDALONE_PACKAGE_DIR = $(DSTDIR)/standalone_package
STANDALONE_PACKAGE_MKDIRS:=$(STANDALONE_PACKAGE_DIR)
STANDALONE_PACKAGE_MKDIRSTAMP:=$(STANDALONE_PACKAGE_DIR)/.dirstamp
TARGETS_STANDALONE_PACKAGE:=$(addprefix $(STANDALONE_PACKAGE_DIR)/,$(addsuffix .ps,$(TARGETS)))
cleanlist += $(TARGETS_STANDALONE_PACKAGE) $(STANDALONE_PACKAGE_MKDIRSTAMP)

RELEASEDIR := $(DSTDIR)/release
RELEASEMKDIRS:=$(RELEASEDIR)
RELEASEMKDIRSTAMP:=$(RELEASEDIR)/.dirstamp
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
#RELEASEFILES+=$(RELEASE_SOURCE_TARBALL)
cleanlist += $(RELEASEFILES) $(RELEASEMKDIRSTAMP)

#------------------------------------------------------------

.PHONY : all clean test resource packaged_resource monolithic monolithic_package release tag

all: resource packaged_resource monolithic monolithic_package

clean:
	$(RM) $(cleanlist)

test:
	tests/run_tests

$(SRCDIR)/%.d: $(SRCDIR)/%.ps $(UPR_FILE)
	$(DSTDIR)/make_deps $< $(addsuffix /Resource,$(RESDIR) $(PACKAGEDIR)) >$@
cleanlist += ${SOURCES:.ps=.d}

ifneq "$(MAKECMDGOALS)" "clean"
-include ${SOURCES:.ps=.d}
endif

#------------------------------------------------------------

resource: $(TARGETS_RES)

$(RESMKDIRSTAMP):
	mkdir -p $(RESMKDIRS)
	touch $@

$(RESDIR)/Resource/uk.co.terryburton.bwipp/%: $(SRCDIR)/%.ps $(SRCDIR)/ps.head $(CHANGES_FILE) $(RESMKDIRSTAMP)
	$(DSTDIR)/make_resource $< $@

$(RESDIR)/Resource/Category/uk.co.terryburton.bwipp: $(SRCDIR)/preamble.ps $(SRCDIR)/ps.head $(CHANGES_FILE) $(RESMKDIRSTAMP)
	$(DSTDIR)/make_resource $< $@

$(RESDIR)/Resource/uk.co.terryburton.bwipp.upr: $(UPR_FILE) $(RESMKDIRSTAMP)
	cp $< $@
$(RESDIR)/README: $(SRCDIR)/README.resource $(RESMKDIRSTAMP)
	cp $< $@
$(RESDIR)/sample.ps: $(SRCDIR)/sample $(RESMKDIRSTAMP)
	cp $< $@
$(RESDIR)/LICENSE: LICENSE $(RESMKDIRSTAMP)
	cp $< $@
$(RESDIR)/CHANGES: CHANGES $(RESMKDIRSTAMP)
	cp $< $@
$(RESDIR)/docs/%: $(DOCDIR)/% $(RESMKDIRSTAMP)
	cp $< $@

#------------------------------------------------------------

packaged_resource: $(TARGETS_PACKAGE)

$(PACKAGEMKDIRSTAMP):
	mkdir -p $(PACKAGEMKDIRS)
	touch $@

$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp/%: $(SRCDIR)/%.ps $(SRCDIR)/ps.head $(CHANGES_FILE) $(PACKAGEMKDIRSTAMP)
	$(DSTDIR)/make_resource $< $@

$(PACKAGEDIR)/Resource/Category/uk.co.terryburton.bwipp: $(SRCDIR)/preamble.ps $(SRCDIR)/ps.head $(CHANGES_FILE) $(PACKAGEMKDIRSTAMP)
	$(DSTDIR)/make_resource $< $@

$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp.upr: $(UPR_FILE) $(PACKAGEMKDIRSTAMP)
	cp $< $@
$(PACKAGEDIR)/README: $(SRCDIR)/README.resource $(PACKAGEMKDIRSTAMP)
	cp $< $@
$(PACKAGEDIR)/sample.ps: $(SRCDIR)/sample $(PACKAGEMKDIRSTAMP)
	cp $< $@
$(PACKAGEDIR)/LICENSE: LICENSE $(PACKAGEMKDIRSTAMP)
	cp $< $@
$(PACKAGEDIR)/CHANGES: CHANGES $(PACKAGEMKDIRSTAMP)
	cp $< $@
$(PACKAGEDIR)/docs/%: $(DOCDIR)/% $(PACKAGEMKDIRSTAMP)
	cp $< $@

#------------------------------------------------------------

monolithic: $(TARGETS_MONOLITHIC)

$(MONOLITHIC_MKDIRSTAMP):
	mkdir -p $(MONOLITHIC_MKDIRS)
	touch $@

$(MONOLITHIC_FILE): $(TARGETS_RES) $(SRCDIR)/ps.head $(CHANGES_FILE) $(UPR_FILE) $(MONOLITHIC_MKDIRSTAMP)
	$(DSTDIR)/make_monolithic $(RESDIR)/Resource >$@
$(MONOLITHIC_FILE_WITH_SAMPLE): $(MONOLITHIC_FILE) $(SRCDIR)/sample $(MONOLITHIC_MKDIRSTAMP)
	cat $(MONOLITHIC_FILE) $(SRCDIR)/sample > $@
$(MONOLITHIC_DIR)/README: $(SRCDIR)/README.monolithic $(MONOLITHIC_MKDIRSTAMP)
	cp $< $@
$(MONOLITHIC_DIR)/LICENSE: LICENSE $(MONOLITHIC_MKDIRSTAMP)
	cp $< $@
$(MONOLITHIC_DIR)/CHANGES: CHANGES $(MONOLITHIC_MKDIRSTAMP)
	cp $< $@
$(MONOLITHIC_DIR)/docs/%: $(DOCDIR)/% $(MONOLITHIC_MKDIRSTAMP)
	cp $< $@

#------------------------------------------------------------

monolithic_package: $(TARGETS_MONOLITHIC_PACKAGE)

$(MONOLITHIC_PACKAGE_MKDIRSTAMP):
	mkdir -p $(MONOLITHIC_PACKAGE_MKDIRS)
	touch $@

$(MONOLITHIC_PACKAGE_FILE): $(TARGETS_PACKAGE) $(SRCDIR)/ps.head $(CHANGES_FILE) $(UPR_FILE) $(MONOLITHIC_PACKAGE_MKDIRSTAMP)
	$(DSTDIR)/make_monolithic $(PACKAGEDIR)/Resource >$@
$(MONOLITHIC_PACKAGE_FILE_WITH_SAMPLE): $(MONOLITHIC_PACKAGE_FILE) $(SRCDIR)/sample $(MONOLITHIC_PACKAGE_MKDIRSTAMP)
	cat $(MONOLITHIC_PACKAGE_FILE) $(SRCDIR)/sample > $@
$(MONOLITHIC_PACKAGE_DIR)/README: $(SRCDIR)/README.monolithic $(MONOLITHIC_PACKAGE_MKDIRSTAMP)
	cp $< $@
$(MONOLITHIC_PACKAGE_DIR)/LICENSE: LICENSE $(MONOLITHIC_PACKAGE_MKDIRSTAMP)
	cp $< $@
$(MONOLITHIC_PACKAGE_DIR)/CHANGES: CHANGES $(MONOLITHIC_PACKAGE_MKDIRSTAMP)
	cp $< $@
$(MONOLITHIC_PACKAGE_DIR)/docs/%: $(DOCDIR)/% $(MONOLITHIC_PACKAGE_MKDIRSTAMP)
	cp $< $@

#------------------------------------------------------------

$(STANDALONE_MKDIRSTAMP):
	mkdir -p $(STANDALONE_MKDIRS)
	touch $@

$(STANDALONE_DIR)/%.ps: $(MONOLITHIC_FILE) $(SRCDIR)/%.ps $(SRCDIR)/ps.head $(CHANGES_FILE) $(STANDALONE_MKDIRSTAMP)
	$(DSTDIR)/make_standalone $< $@

#------------------------------------------------------------

$(STANDALONE_PACKAGE_MKDIRSTAMP):
	mkdir -p $(STANDALONE_PACKAGE_MKDIRS)
	touch $@

$(STANDALONE_PACKAGE_DIR)/%.ps: $(MONOLITHIC_PACKAGE_FILE) $(SRCDIR)/%.ps $(SRCDIR)/ps.head $(CHANGES_FILE) $(STANDALONE_PACKAGE_MKDIRSTAMP)
	$(DSTDIR)/make_standalone $< $@

#------------------------------------------------------------

release: $(RELEASEFILES)

$(RELEASEMKDIRSTAMP):
	mkdir -p $(RELEASEMKDIRS)
	touch $@

define TARBALL
  tar --exclude-vcs --exclude=.dirstamp --numeric-owner --owner=0 --group=0 --mtime=./$(CHANGES_FILE) --transform='s,^$(DSTDIR)/,postscriptbarcode-$(VERSION)/,' -czf $@ $(1)
endef

define ZIPFILE
  $(RM) $@; FILE=`readlink -f $@` && cd $(1) && zip -q -X -x '*.dirstamp' -r $$FILE .
endef

$(RELEASE_RESOURCE_TARBALL): $(TARGETS_RES) $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
	$(call TARBALL,$(RESDIR))

$(RELEASE_RESOURCE_ZIPFILE): $(TARGETS_RES) $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
	$(call ZIPFILE,$(RESDIR))

$(RELEASE_PACKAGED_RESOURCE_TARBALL): $(TARGETS_PACKAGE) $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
	$(call TARBALL,$(PACKAGEDIR))

$(RELEASE_PACKAGED_RESOURCE_ZIPFILE): $(TARGETS_PACKAGE) $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
	$(call ZIPFILE,$(PACKAGEDIR))

$(RELEASE_MONOLITHIC_TARBALL): $(TARGETS_MONOLITHIC) $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
	$(call TARBALL,$(MONOLITHIC_DIR))

$(RELEASE_MONOLITHIC_ZIPFILE): $(TARGETS_MONOLITHIC) $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
	$(call ZIPFILE,$(MONOLITHIC_DIR))

$(RELEASE_MONOLITHIC_PACKAGE_TARBALL): $(TARGETS_MONOLITHIC_PACKAGE) $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
	$(call TARBALL,$(MONOLITHIC_PACKAGE_DIR))

$(RELEASE_MONOLITHIC_PACKAGE_ZIPFILE): $(TARGETS_MONOLITHIC_PACKAGE) $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
	$(call ZIPFILE,$(MONOLITHIC_PACKAGE_DIR))

#$(RELEASE_SOURCE_TARBALL): $(CHANGES_FILE) $(RELEASEMKDIRSTAMP)
#	tar --exclude-vcs --exclude=$(RELEASEDIR) $(addprefix --exclude=,$(cleanlist)) --numeric-owner --owner=0 --group=0 --mtime=./$(CHANGES_FILE) --transform='s,^.,postscriptbarcode-$(VERSION),' -czf $@ .

#------------------------------------------------------------

tag:
	@echo Push a new tag as follows:
	@echo
	@echo "git tag -s -F /dev/stdin `head -n1 CHANGES` <<'EOF'"
	@echo "`awk -v 'RS=\n\n\n' -v 'FS=\n\n' '{print $$2;exit}' CHANGES`"
	@echo EOF
	@echo git push origin `head -n1 CHANGES`
