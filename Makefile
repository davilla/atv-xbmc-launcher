# Makefile
#
# Copyright (C) 2008 Team-XBMC
# based on version from  Eric Steil III for ATVFiles
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

#######
# variables
#######
VERSION=0.1
PROJNAME=MultiFinderAllInOne

DISTCONFIG=Debug
EXTRA_OPTS= 
CMAKEBUILDFOLDER=build-cmake
DISTROOT=dist
TMPROOT=$(DISTROOT)/tmp
TARDIR=$(PROJNAME)-$(VERSION)

# sfx archive settings
RUNARCHIVENAME=$(PROJNAME)-$(VERSION).zip
RUNBALL=$(DISTROOT)/$(PROJNAME)-$(VERSION).run
#######
# targets
#######

default: testdist

clean: 
	rm -rf "$(DISTFOLDER)" xbmclauncher/dist/* "$(CMAKEBUILDFOLDER)" xbmclauncher/build/*

$(CMAKEBUILDFOLDER)/MultiFinder/$(DISTCONFIG)/MultiFinder.app:
	mkdir -p "$(CMAKEBUILDFOLDER)"
	cd "$(CMAKEBUILDFOLDER)" && cmake .. -GXcode 
	cd "$(CMAKEBUILDFOLDER)" && xcodebuild -configuration "$(DISTCONFIG)" clean $(EXTRA_OPTS) 
	cd "$(CMAKEBUILDFOLDER)" && xcodebuild -configuration "$(DISTCONFIG)" -target MultiFinder $(EXTRA_OPTS)

dist-debug-XBMCLauncher:
	cd xbmclauncher && $(MAKE) dist-debug

dist-sfx: $(CMAKEBUILDFOLDER)/MultiFinder/$(DISTCONFIG)/MultiFinder.app
	@echo "BUILDING SFX DISTRIBUTION FOR $(PROJNAME) $(VERSION) ($(REVISION))"
	
	mkdir -p "$(TMPROOT)/ARCTEMP/$(TARDIR)"
	mkdir -p "$(TMPROOT)/$(TARDIR)"
	rm -f "$(RUNBALL)"
	
	#copy multifinder
	ditto "$(CMAKEBUILDFOLDER)/MultiFinder/$(DISTCONFIG)/" "$(TMPROOT)/ARCTEMP/$(TARDIR)"
	#copy xbmclauncher don't know the name, so just use .run for now
	cp xbmclauncher/dist/*.run "$(TMPROOT)/ARCTEMP/$(TARDIR)"
		
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

dist-debug: clean dist-debug-XBMCLauncher dist-sfx
	$(MAKE) dist DISTCONFIG=Debug EXTRA_OPTS="RELEASE_SUFFIX=\"-debug\"" VERSION="$(VERSION)-debug"
		
.PHONY: default clean buildMultiFinder buildXBMCLauncher build dist release dist-tarball testdist testrel dist-sfx