#!/bin/bash
#-----------------------------------------------------------------------------------------
# BASH Script for Apple TV to Install Boxee. 
#
# based on scripts by S.Diederich, Vulkanr, hillbilly1980 (Keith), Jim Wiley and others
#
# Installs wget, unzip, turbo_atv_enabler, FLash 10.0, CoreAudioKit.framework & Boxee Beta
# and creates Apple TV specific advancedsettings.xml
#-----------------------------------------------------------------------------------------
#

DISKIMAGE=$1

echo "Installing from diskimage $DISKIMAGE"
# check that disk-image exists
if [ -e $DISKIMAGE ]; then
	
	PW="frontrow"

	# check and store OSBoot read/write settings
	REMOUNT=0
	# Check if / is mounted read only
	if mount | grep ' on / '  | grep -q 'read-only'; then
		REMOUNT=1
		echo $PW | sudo -S /sbin/mount -uw /
	fi
	
	filedir=/Users/frontrow/BoxeeBetaInstall/
	appdir=/Users/frontrow/Applications/
	plugdir=/Users/frontrow/Library/Internet\ Plug-Ins/
	
	if [ ! -d "$filedir" ]; then
		echo $PW | sudo -S mkdir "$filedir"
		echo $PW | sudo -S chown -R frontrow:frontrow "$filedir"
	fi
	
	cd $filedir
	sudo rm -rdf "$filedir"*
	
	if [ ! -d "$appdir" ]; then
			echo $PW | sudo -S mkdir "$appdir"
			echo $PW | sudo -S chown -R frontrow:frontrow "$appdir"
	fi
	
	if [ ! -d "$plugdir" ]; then
			echo $PW | sudo -S mkdir "$plugdir"
			echo $PW | sudo -S chown -R frontrow:frontrow "$plugdir"
			echo $PW | sudo -S mkdir /Library/Internet\ Plug-Ins/
	fi
	
	### INSTALL NECESSARY UNIX TOOLS ###
	if [ ! -f /usr/bin/wget ]; then
		echo -n "Downloading wget: 107KB"
		echo $PW | sudo -S hdiutil attach -quiet http://www.green-light.ca/cmn_external/app/boxee/beta/wget.dmg &
		while ps |grep $! &>/dev/null; do
			echo -n "."
			sleep 2
		done
		echo "Installing wget"
		echo $PW | sudo -S cp -rp /Volumes/wget/wget /usr/bin/wget
		echo $PW | sudo -S chmod 755 /usr/bin/wget	
		echo $PW | sudo -S chown root:wheel /usr/bin/wget
		echo $PW | sudo -S hdiutil unmount -quiet /Volumes/wget/
	fi
	
	if [ ! -f /usr/bin/unzip ]; then
		wget http://awkwardtv.sourceforge.net/tools/unzip
		echo $PW | sudo -S mv -f unzip /usr/bin/
		echo $PW | sudo -S chmod 755 /usr/bin/unzip
		echo $PW | sudo -S chown root:wheel /usr/bin/unzip
	fi
	
	### INSTALL turbo_atv_enabler.bin ###
	# First check if User has rc.local - if not create:
	if [[ ! -e /etc/rc.local ]]; then
		echo $PW | sudo -S touch /etc/rc.local
		echo $PW | sudo -S chmod 644 /etc/rc.local
		echo $PW | sudo -S chown root:wheel /etc/rc.local
	fi
	
	# Check if turbo has an entry in rc.local, if not grab and install!
	if [[ `egrep -ic "turbo" "/etc/rc.local"` != "1" ]]; then
		wget http://code.google.com/p/crystalhd-for-osx/downloads/list/turbo_atv_enabler.bin
		echo $PW | sudo -S mv turbo_atv_enabler.bin /sbin/turbo_atv_enabler.bin
		echo $PW | sudo -S chmod 755 /sbin/turbo_atv_enabler.bin
		echo $PW | sudo -S chown root:wheel /sbin/turbo_atv_enabler.bin
		echo $PW | sudo -S mv /etc/rc.local "$filedir"rc.local.tmp
		echo $PW | sudo -S chmod 755 "$filedir"rc.local.tmp
		echo $PW | sudo -S chown frontrow:frontrow "$filedir"rc.local.tmp
		echo $PW | sudo -S touch "$filedir"rc.local
		echo $PW | sudo -S chmod 755 "$filedir"rc.local
		echo $PW | sudo -S chown frontrow:frontrow "$filedir"rc.local
		echo $PW | sudo -S echo "/sbin/turbo_atv_enabler.bin" >> "$filedir"rc.local
		echo $PW | sudo -S cat "$filedir"rc.local.tmp >> "$filedir"rc.local
		echo $PW | sudo -S mv "$filedir"rc.local /etc/rc.local
		echo $PW | sudo -S chmod 644 /etc/rc.local
		echo $PW | sudo -S chown root:wheel /etc/rc.local
		echo $PW | sudo -S /sbin/turbo_atv_enabler.bin
	fi
		
	### INSTALL FLASH PLUGIN ####
	# Uninstall any existing plugin and remove any symlinks
	if [[ -d "$plugdir"Flash\ Player.plugin  ]]; then
		echo $PW | sudo -S rm -rf "$plugdir"Flash\ Player.plugin
		echo $PW | sudo -S rm -f "$plugdir"flashplayer.xpt
  	fi
  	if [[ -h /Library/Internet\ Plug-Ins/Flash\ Player.plugin  ]]; then
  		echo $PW | sudo -S rm -f /Library/Internet\ Plug-Ins/Flash\ Player.plugin
  		echo $PW | sudo -S rm -f /Library/Internet\ Plug-Ins/flashplayer.xpt
  	fi
  	if [[ -d /Library/Internet\ Plug-Ins/Flash\ Player.plugin  ]]; then
  		echo $PW | sudo -S rm -rf /Library/Internet\ Plug-Ins/Flash\ Player.plugin
  		echo $PW | sudo -S rm -f /Library/Internet\ Plug-Ins/flashplayer.xpt
  	fi
	  
	echo "Downloading Flash Plugin: 5.4MB"
	wget http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_osx_ub.dmg
	echo "Installing Flash Plugin"
	echo $PW | sudo -S hdiutil attach install_flash_player_osx_ub.dmg
	echo $PW | sudo -S pax -r -z -f /Volumes/Install\ Flash\ Player\ 10\ UB/Adobe\ Flash\ Player.pkg/Contents/Archive.pax.gz
	echo $PW | sudo -S rm -Rd Flash\ Player.plugin/Contents/Resources/{c,d,f,i,j,k,n,p,r,s,t,z,e}*.lproj
	echo $PW | sudo -S mv Flash\ Player.plugin "$plugdir"
	echo $PW | sudo -S mv flashplayer.xpt "$plugdir"
	echo $PW | sudo -S hdiutil detach /Volumes/Install\ Flash\ Player\ 10\ UB/
	
	# Create symlinks in /Library/Internet Plug-Ins/
	echo $PW | sudo -S ln -s "$plugdir"Flash\ Player.plugin /Library/Internet\ Plug-Ins/
	echo $PW | sudo -S ln -s "$plugdir"flashplayer.xpt /Library/Internet\ Plug-Ins/  
	
	### INSTALL CoreAudioKit.framework ####
	if [[ `egrep -ic "180092" "/System/Library/Frameworks/CoreAudioKit.framework/Versions/Current/Resources/version.plist"` != "1" ]]; then
		echo "Downloading COREAUDIOKIT: 93KB"
		wget http://www.green-light.ca/cmn_external/app/boxee/beta/CoreAudioKit.framework.zip
		echo "Installing COREAUDIOKIT"
		echo $PW | sudo -S unzip CoreAudioKit.framework.zip
		rm CoreAudioKit.framework.zip
		echo $PW | sudo -S cp -r CoreAudioKit.framework/ /System/Library/Frameworks/CoreAudioKit.framework
		echo $PW | sudo -S chown -R root:wheel /System/Library/Frameworks/CoreAudioKit.framework/
	fi
	
	### INSTALL BOXEE BETA APP ###
	if [[ -d /Users/frontrow/Applications/Boxee.app && ! -d /Users/frontrow/Applications/Boxee.old.app ]]; then
		echo $PW | sudo -S mv /Users/frontrow/Applications/Boxee.app /Users/frontrow/Applications/Boxee.old.app
		echo $PW | sudo -S mv /Users/frontrow/Library/Application\ Support/BOXEE /Users/frontrow/Library/Application\ Support/BOXEE.old
	fi
	
	if [[ -d /Applications/Boxee.app && ! -d /Users/frontrow/Applications/Boxee.old-user.app ]]; then
		echo $PW | sudo -S mv /Applications/Boxee.app /Users/frontrow/Applications/Boxee.old-user.app
		echo $PW | sudo -S mv /Library/Application\ Support/BOXEE /Users/frontrow/Library/Application\ Support/BOXEE.old-user
	fi
	
	if [ -f "$DISKIMAGE" ]; then
		echo "Found a local Boxee image, using instead local, not looking for newer copies"
		ln -s "$DISKIMAGE" boxee-users.dmg
	else
		echo "Downloading Boxee Beta"
		wget http://www.green-light.ca/cmn_external/app/boxee/beta/latest
	fi
	
	echo -e "Installing Boxee"
	echo $PW | sudo -S hdiutil mount boxee-*.dmg
	echo $PW | sudo -S ln -s /Volumes/boxee-* /Volumes/boxee
	pax -r -z -f /Volumes/boxee/boxee-*.mpkg/Contents/Packages/boxee.pkg/Contents/Archive.pax.gz
	echo $PW | sudo -S rm -rf /Applications/Boxee.app
	echo $PW | sudo -S mv Boxee.app /Applications/
	echo $PW | sudo -S hdiutil unmount /Volumes/boxee-*/
	echo $PW | sudo -S rm /Volumes/boxee
	echo $PW | sudo -S rm boxee-*.dmg
	
	### POST BOXEE INSTALL ###
	# If Boxee working directory does not exist (i.e. first install) then make it
	if [ ! -d "/Users/frontrow/Library/Application Support/BOXEE/userdata/" ]; then
		mkdir -p "/Users/frontrow/Library/Application Support/BOXEE/userdata/"
	fi
	
	# Check for advancedsettings.xml, if doesn't exist, put in standard ATV settings
	AVDSETTINGS_PATH="/Users/frontrow/Library/Application Support/BOXEE/userdata/advancedsettings.xml"
	if [ ! -e "$AVDSETTINGS_PATH" ]; then
		echo "<advancedsettings><skiploopfilter>8</skiploopfilter><osx_gl_fullscreen>true</osx_gl_fullscreen></advancedsettings>" >> "$AVDSETTINGS_PATH"
	else  	
		# advanced settings exists, but does skiploopfilter setting? If not, put it in!
		grep -q skiploopfilter "$AVDSETTINGS_PATH"
		if [ $? -eq 0 ]; then
			echo "skiploopfiler present in advancedsettings.xml"
		else
			echo "skiploopfiler not present, adding it to advancedsettings.xml"
			sed -e s#\<advancedsettings\>#\<advancedsettings\>\<skiploopfilter\>8\</skiploopfilter\>#g -i "" "$AVDSETTINGS_PATH"
		fi
		
		# Does osx_gl_fullscreen setting exist? If not, put it in!
		grep -q osx_gl_fullscreen "$AVDSETTINGS_PATH"
		if [ $? -eq 0 ]; then 
			echo "osx_gl_fullscreen present in advancedsettings.xml"
		else
			echo "osx_gl_fullscreen not present, adding it to advancedsettings.xml"
			sed -e s#\</advancedsettings\>#\<osx_gl_fullscreen\>true\</osx_gl_fullscreen\>\</advancedsettings\>#g -i "" "$AVDSETTINGS_PATH"
		fi  
	  fi
	
	echo $PW | sudo -S chown -R frontrow "/Users/frontrow/Library/Application Support/BOXEE"
	
	### POST INSTALL CLEAN UP ###
	cd ..

	echo $PW | sudo -S rm -rdf $filedir
	echo $PW | sudo -S chmod -R 755 /Users/frontrow/Library/Internet\ Plug-Ins
	echo $PW | sudo -S chown -R frontrow:frontrow /Users/frontrow/Library/Internet\ Plug-Ins
	
	#sync to disk, just in case...
	/bin/sync
	
	# restore OSBoot read/write settings
	if [ "$REMOUNT" = "1" ]; then
		echo $PW | sudo -S /sbin/mount -ur /
	fi
	
	echo "Installation successful Finished!"
	exit 0

fi

echo "Failed to find diskimage $DISKIMAGE"
exit -1

