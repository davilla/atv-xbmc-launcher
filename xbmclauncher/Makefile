# Makefile
#
# Copyright (C) 2007 Eric Steil III
# shrinked for XBMCLauncher by Stephan Diederich
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

REVISION=$(shell agvtool vers -terse)
VERSION=$(shell tools/xcodeversion version -terse)
PROJNAME=XBMCLauncher

DISTROOT=dist
TMPROOT=$(DISTROOT)/tmp
DISTCONFIG=Release

# tarball archive settings
TARDIR=$(PROJNAME)-$(VERSION)
TARBALL=$(DISTROOT)/$(PROJNAME)-$(VERSION).tar.gz

# sfx archive settings
RUNARCHIVENAME=$(PROJNAME)-$(VERSION).zip
RUNBALL=$(DISTROOT)/$(PROJNAME)-$(VERSION).run

TEST_VERSION_SUFFIX_DATE=$(shell date +"%y.%m.%d.%H%M")
TEST_VERSION_SUFFIX=-TEST-$(TEST_VERSION_SUFFIX_DATE)
TEST_VERSION=$(VERSION)$(TEST_VERSION_SUFFIX)

EXTRA_OPTS=

# doc settings
README_SOURCE=README.txt
README_DEST=dist/README.txt
LICENSE_SOURCE=LICENSE.txt
LICENSE_DEST=dist/LICENSE.txt

default: build

strings: English.lproj/Localizable.strings
	
English.lproj/Localizable.strings: *.m
	genstrings -s BRLocalizedString -o English.lproj *.m
		
build:
	xcodebuild -configuration Debug
	
release: build/$(DISTCONFIG)/XBMCLauncher.frappliance/Contents/MacOS/XBMCLauncher

build/$(DISTCONFIG)/XBMCLauncher.frappliance/Contents/MacOS/XBMCLauncher: src/*.h src/*.m src/updater/*.h src/updater/*.m src/helpers/*.h src/helpers/*.m
	xcodebuild -configuration "$(DISTCONFIG)" clean $(EXTRA_OPTS)
	xcodebuild -configuration "$(DISTCONFIG)" $(EXTRA_OPTS)

	rm -rf "build/$(DISTCONFIG)/XBMCLauncher.frappliance.dSYM"

docs: $(README_DEST) $(LICENSE_DEST)
	mkdir -p "build/$(DISTCONFIG)/"
	cp "$(README_SOURCE)" "$(LICENSE_SOURCE)" "build/$(DISTCONFIG)/"
	
$(README_DEST): $(README_SOURCE)
	mkdir -p "$(README_DEST)"
	cp $(README_SOURCE) $(README_DEST)
	
$(LICENSE_DEST): $(LICENSE_SOURCE)
	mkdir -p "$(LICENSE_DEST)"
	cp $(LICENSE_SOURCE) $(LICENSE_DEST)

# Build the tarball for ATVLoader
dist-tarball: docs release 
	@echo "BUILDING DISTRIBUTION FOR XBMCLauncher $(VERSION) ($(REVISION))"
	
	# build tarball
	mkdir -p "$(TMPROOT)/$(TARDIR)"
	rm -f "$(TARBALL)"
	
	# copy contents to tmproot
	ditto "build/$(DISTCONFIG)/" "$(TMPROOT)/$(TARDIR)"
	
	tar -C "$(TMPROOT)" -czf "$(PWD)/$(TARBALL)" "$(TARDIR)"
	rm -rf "$(TMPROOT)"
	
# Build the self-extracting archive
dist-sfx: docs release
	@echo "BUILDING SFX DISTRIBUTION FOR XBMCLauncher $(VERSION) ($(REVISION))"
	
	mkdir -p "$(TMPROOT)/ARCTEMP/$(TARDIR)"
	mkdir -p "$(TMPROOT)/$(TARDIR)"
	rm -f "$(RUNBALL)"
	
	ditto "build/$(DISTCONFIG)/" "$(TMPROOT)/ARCTEMP/$(TARDIR)"
	mv "$(TMPROOT)/ARCTEMP/$(TARDIR)/README.txt" "$(TMPROOT)/$(TARDIR)/README.txt"
	mv "$(TMPROOT)/ARCTEMP/$(TARDIR)/LICENSE.txt" "$(TMPROOT)/$(TARDIR)/LICENSE.txt"
	
	# build the archive of this
	ditto -c -k --rsrc "$(TMPROOT)/ARCTEMP/$(TARDIR)" "$(TMPROOT)/$(TARDIR)/$(RUNARCHIVENAME)"
	rm -rf "$(TMPROOT)/$(TARDIR)/ARCTEMP"
	
	sed -e "s,@VERSION@,$(VERSION),g" \
		-e "s,@TARDIR@,$(TARDIR),g" \
		-e "s,@ARCHIVE_NAME@,$(RUNARCHIVENAME),g" \
		< tools/install.sh > "$(TMPROOT)/$(TARDIR)/install.sh"
	chmod a+x "$(TMPROOT)/$(TARDIR)/install.sh"
	
	# build the sfx
	makeself.sh --nocrc --nocomp --nox11 "$(TMPROOT)/$(TARDIR)" "$(RUNBALL)" "$(PROJNAME) $(VERSION)" "./install.sh"
		
	rm -rf "$(TMPROOT)"
		
dist: dist-tarball dist-sfx
	
dist-debug:
	$(MAKE) dist DISTCONFIG=Debug EXTRA_OPTS="RELEASE_SUFFIX=\"-debug\"" VERSION="$(VERSION)-debug"
	
fulldist: dist dist-debug

testrel:
	echo "Building release nightly"
	$(MAKE) dist VERSION="$(TEST_VERSION)" EXTRA_OPTS="RELEASE_SUFFIX=\"$(TEST_VERSION_SUFFIX)\""
	
testdist:
	echo "Building debug distribution $(TEST_VERSION)"
	$(MAKE) dist DISTCONFIG=Debug VERSION="$(TEST_VERSION)" EXTRA_OPTS="RELEASE_SUFFIX=\"$(TEST_VERSION_SUFFIX)\""
	
.PHONY: default build dist release dist-tarball testdist testrel dist-sfx

