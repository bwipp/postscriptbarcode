# Barcode Writer in Pure PostScript
# https://bwipp.terryburton.co.uk
#
# Copyright (c) 2004-2026 Terry Burton
#
# $Id$

SRCDIR = src
DOCDIR = docs
DSTDIR = build

CHANGES_FILE=CHANGES
VERSION:=$(shell head -n 1 $(CHANGES_FILE))

SOURCES:=$(wildcard $(SRCDIR)/*.ps.src)

DOCNAMES:=$(notdir $(wildcard $(DOCDIR)/*))

TARGETS:=$(notdir $(SOURCES:.ps.src=))
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

STANDALONE_PACKAGE_DIR = $(DSTDIR)/standalone_package
STANDALONE_PACKAGE_MKDIRS:=$(STANDALONE_PACKAGE_DIR)
STANDALONE_PACKAGE_MKDIRSTAMP:=$(STANDALONE_PACKAGE_DIR)/.dirstamp
TARGETS_STANDALONE_PACKAGE:=$(addprefix $(STANDALONE_PACKAGE_DIR)/,$(addsuffix .ps,$(TARGETS)))

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

.PHONY: all
all: resource packaged_resource monolithic monolithic_package

.PHONY: clean
clean:
	$(RM) $(cleanlist)

.PHONY: test
test: all
	tests/run_tests

$(SRCDIR)/%.ps.d: $(SRCDIR)/%.ps.src $(UPR_FILE)
	$(DSTDIR)/make_deps.pl $< $(addsuffix /Resource,$(RESDIR) $(PACKAGEDIR)) >$@
cleanlist += ${SOURCES:.ps.src=.ps.d}

ifneq "$(MAKECMDGOALS)" "clean"
-include ${SOURCES:.ps.src=.ps.d}
endif

#------------------------------------------------------------

.PHONY: resource
resource: $(TARGETS_RES)

$(RESMKDIRSTAMP):
	mkdir -p $(RESMKDIRS)
	touch $@

$(RESDIR)/Resource/uk.co.terryburton.bwipp/%: $(SRCDIR)/%.ps.src $(SRCDIR)/ps.head $(CHANGES_FILE) $(RESMKDIRSTAMP)
	$(DSTDIR)/make_resource.pl $< $@

$(RESDIR)/Resource/Category/uk.co.terryburton.bwipp: $(SRCDIR)/preamble.ps.src $(SRCDIR)/ps.head $(CHANGES_FILE) $(RESMKDIRSTAMP)
	$(DSTDIR)/make_resource.pl $< $@

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
#
# Auto-generate atload names list for packaged resources
#

$(DSTDIR)/make_packaged_resource.ps.names: $(SOURCES)
	@grep -rh '^[^%]*//[a-zA-Z][a-zA-Z0-9._-]*' $(SRCDIR)/*.ps.src | \
	  grep -oh '//[a-zA-Z][a-zA-Z0-9._-]*' | \
	  sed 's|^//||' | sort -u | tr '\n' ' ' | \
	  sed 's/ $$//' > $@.tmp; \
	if ! cmp -s $@ $@.tmp 2>/dev/null; then mv $@.tmp $@; else rm -f $@.tmp; fi

$(DSTDIR)/make_packaged_resource.ps: $(DSTDIR)/make_packaged_resource.ps.in $(DSTDIR)/make_packaged_resource.ps.names
	sed "s/@@ATLOAD_NAMES@@/$$(cat $(DSTDIR)/make_packaged_resource.ps.names)/" $< > $@

cleanlist += $(DSTDIR)/make_packaged_resource.ps $(DSTDIR)/make_packaged_resource.ps.names

#------------------------------------------------------------

.PHONY: packaged_resource
packaged_resource: $(TARGETS_PACKAGE)

$(PACKAGEMKDIRSTAMP):
	mkdir -p $(PACKAGEMKDIRS)
	touch $@

$(PACKAGEDIR)/Resource/uk.co.terryburton.bwipp/%: $(SRCDIR)/%.ps.src $(SRCDIR)/ps.head $(CHANGES_FILE) $(DSTDIR)/make_packaged_resource.ps $(PACKAGEMKDIRSTAMP)
	$(DSTDIR)/make_resource.pl $< $@

$(PACKAGEDIR)/Resource/Category/uk.co.terryburton.bwipp: $(SRCDIR)/preamble.ps.src $(SRCDIR)/ps.head $(CHANGES_FILE) $(DSTDIR)/make_packaged_resource.ps $(PACKAGEMKDIRSTAMP)
	$(DSTDIR)/make_resource.pl $< $@

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

.PHONY: monolithic
monolithic: $(TARGETS_MONOLITHIC)

$(MONOLITHIC_MKDIRSTAMP):
	mkdir -p $(MONOLITHIC_MKDIRS)
	touch $@

$(MONOLITHIC_FILE): $(TARGETS_RES) $(SRCDIR)/ps.head $(CHANGES_FILE) $(UPR_FILE) $(MONOLITHIC_MKDIRSTAMP)
	$(DSTDIR)/make_monolithic.pl $(RESDIR)/Resource >$@
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

.PHONY: monolithic_package
monolithic_package: $(TARGETS_MONOLITHIC_PACKAGE)

$(MONOLITHIC_PACKAGE_MKDIRSTAMP):
	mkdir -p $(MONOLITHIC_PACKAGE_MKDIRS)
	touch $@

$(MONOLITHIC_PACKAGE_FILE): $(TARGETS_PACKAGE) $(SRCDIR)/ps.head $(CHANGES_FILE) $(UPR_FILE) $(MONOLITHIC_PACKAGE_MKDIRSTAMP)
	$(DSTDIR)/make_monolithic.pl $(PACKAGEDIR)/Resource >$@
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

$(STANDALONE_DIR)/%.ps: $(SRCDIR)/%.ps.src $(SRCDIR)/ps.head $(CHANGES_FILE) $(STANDALONE_MKDIRSTAMP)
	$(DSTDIR)/make_standalone.pl $(RESDIR)/Resource $@

#------------------------------------------------------------

$(STANDALONE_PACKAGE_MKDIRSTAMP):
	mkdir -p $(STANDALONE_PACKAGE_MKDIRS)
	touch $@

$(STANDALONE_PACKAGE_DIR)/%.ps: $(SRCDIR)/%.ps.src $(SRCDIR)/ps.head $(CHANGES_FILE) $(STANDALONE_PACKAGE_MKDIRSTAMP)
	$(DSTDIR)/make_standalone.pl $(PACKAGEDIR)/Resource $@

#------------------------------------------------------------

.PHONY: release
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

.PHONY: tag
tag:
	@echo Push a new tag as follows:
	@echo
	@echo Remenber to refresh the wikidocs/ submodule
	@echo
	@echo "git tag -s -F /dev/stdin `head -n1 CHANGES` <<'EOF'"
	@echo "`awk -v 'RS=\n\n\n' -v 'FS=\n\n' '{print $$2;exit}' CHANGES`"
	@echo EOF
	@echo git push upstream `head -n1 CHANGES`

YEAR:=$(shell date +%Y)

.PHONY: copyright
copyright:
	sed -i -e 's@\(Copyright\)\(.*\)\(2004-\)\([[:digit:]]\+\)\( Terry Burton\)@\1\2\3$(YEAR)\5@' $(SOURCES) LICENSE Makefile $(SRCDIR)/ps.head $(DSTDIR)/make_packaged_resource.ps.in $(DSTDIR)/make_resource.ps libs/bindings/postscriptbarcode.i libs/c/*.[ch]

.PHONY: whitespace
whitespace:
	perl -p -i -e 's/\s+$$/\n/;' $(SOURCES)


#
#  GS1 Syntax Dictionary sync helper
#
GS1_SYNTAX_DICT = contrib/development/gs1-syntax-dictionary.txt
GS1_SYNTAX_BUILD = contrib/development/build-gs1-syntax-dict.pl
GS1_SYNTAX_TARGET = $(SRCDIR)/gs1process.ps.src

.PHONY: syncsyntaxdict
syncsyntaxdict:
	@echo "Fetching latest GS1 Syntax Dictionary release..."
	@TAG=$$(curl -sf https://api.github.com/repos/gs1/gs1-syntax-dictionary/releases/latest | \
		grep '"tag_name":' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'); \
	if [ -z "$$TAG" ]; then echo "Error: Failed to fetch release info" >&2; exit 1; fi; \
	echo "Latest release: $$TAG"; \
	curl -sfL "https://raw.githubusercontent.com/gs1/gs1-syntax-dictionary/$$TAG/gs1-syntax-dictionary.txt" \
		-o $(GS1_SYNTAX_DICT).tmp || { echo "Error: Failed to download syntax dictionary" >&2; exit 1; }; \
	mv $(GS1_SYNTAX_DICT).tmp $(GS1_SYNTAX_DICT); \
	echo "Regenerating gs1syntax block..."; \
	cp $(GS1_SYNTAX_TARGET) $(GS1_SYNTAX_TARGET).orig; \
	perl -T $(GS1_SYNTAX_BUILD) < $(GS1_SYNTAX_DICT) | \
		sed 's/>> def$$/>> readonly def/' > $(GS1_SYNTAX_TARGET).gs1syntax.tmp; \
	START=$$(grep -n '/gs1syntax <<' $(GS1_SYNTAX_TARGET) | cut -d: -f1); \
	END=$$(awk '/\/gs1syntax <</{start=NR} start && />> readonly def/{print NR; exit}' $(GS1_SYNTAX_TARGET)); \
	if [ -z "$$START" ] || [ -z "$$END" ]; then echo "Error: Failed to locate gs1syntax block" >&2; exit 1; fi; \
	head -n $$((START - 1)) $(GS1_SYNTAX_TARGET) > $(GS1_SYNTAX_TARGET).tmp; \
	cat $(GS1_SYNTAX_TARGET).gs1syntax.tmp >> $(GS1_SYNTAX_TARGET).tmp; \
	tail -n +$$((END + 1)) $(GS1_SYNTAX_TARGET) >> $(GS1_SYNTAX_TARGET).tmp; \
	mv $(GS1_SYNTAX_TARGET).tmp $(GS1_SYNTAX_TARGET); \
	rm -f $(GS1_SYNTAX_TARGET).gs1syntax.tmp; \
	echo "Done. Updated $(GS1_SYNTAX_TARGET) with GS1 Syntax Dictionary $$TAG"; \
	echo ""; \
	diff -u -w $(GS1_SYNTAX_TARGET).orig $(GS1_SYNTAX_TARGET) || true; \
	rm -f $(GS1_SYNTAX_TARGET).orig

