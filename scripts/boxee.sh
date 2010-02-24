#!/bin/bash
#-------------------------------------------------------------------
# BASH Script for Apple TV to Install Boxee. 
# Requires: SSH
# based on the great work by JimWiley & hillbilly1980
#-------------------------------------------------------------------
#
DISKIMAGE=$1
PW="frontrow"

echo $PW | sudo -S mount -uw /
filedir=/Users/frontrow/BoxeeBetaInstall/
appdir=/Users/frontrow/Applications/
plugdir=/Users/frontrow/Library/Internet\ Plug-Ins/

if [ ! -d "$filedir" ]; then
	mkdir $filedir
	sudo chown -R frontrow:frontrow $filedir
fi

cd $filedir
sudo rm -rdf "$filedir"*

if [ ! -d "$appdir" ]; then
    	mkdir $appdir
	sudo chown -R frontrow:frontrow $appdir
fi
if [ ! -d "$plugdir" ]; then
    	sudo mkdir /Library/Internet\ Plug-Ins/
fi

if [ ! -f /usr/bin/wget ]; then
	echo -n "Downloading wget: 107KB"
	sudo hdiutil attach -quiet http://www.green-light.ca/cmn_external/app/boxee/beta/wget.dmg &
	while ps |grep $! &>/dev/null; do
   		echo -n "."
   		sleep 2
	done
	echo "Installing wget"
	sudo cp -rp /Volumes/wget/wget /usr/bin/wget
	sudo chmod 755 /usr/bin/wget	
	sudo chown root:wheel /usr/bin/wget
	sudo hdiutil unmount -quiet /Volumes/wget/
fi
if [ ! -f /usr/bin/unzip ]; then
	wget http://awkwardtv.sourceforge.net/tools/unzip

	chmod 755 unzip
	sudo mv -f unzip /usr/bin/
	sudo chown root:wheel /usr/bin/unzip
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
	wget http://0xfeedbeef.com/appletv/turbo_atv_enabler.bin
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
	
### FLASH PLUGIN ####
# First move any existing plugin to $plugdir
  	if [[ -d /Library/Internet\ Plug-Ins/Flash\ Player.plugin  && ! -h /Library/Internet\ Plug-Ins/Flash\ Player.plugin ]]; then
  	    	echo $PW | sudo -S mv /Library/Internet\ Plug-Ins/Flash\ Player.plugin "$plugdir"
  			echo $PW | sudo -S mv /Library/Internet\ Plug-Ins/flashplayer.xpt "$plugdir"
	fi
  
if [[ `egrep -ic "10.0.45.2" "/Users/frontrow/Library/Internet Plug-Ins/Flash Player.plugin/Contents/Info.plist"` != "1" ]]; then
	echo "Downloading Flash Plugin: 5.4MB"
	wget http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_osx_ub.dmg
	echo "Installing Flash Plugin"
	sudo hdiutil mount install_flash_player_osx_ub.dmg
	pax -r -z -f /Volumes/Install\ Flash\ Player\ 10\ UB/Adobe\ Flash\ Player.pkg/Contents/Archive.pax.gz
	sudo hdiutil unmount /Volumes/Install\ Flash\ Player\ 10\ UB/
	rm -Rd Flash\ Player.plugin/Contents/Resources/{c,d,f,i,j,k,n,p,r,s,t,z,e}*.lproj
	sudo rm -rf "$plugdir"Flash\ Player.plugin
	sudo rm -rf "$plugdir"flashplayer.xpt
	sudo mv Flash\ Player.plugin/ "$plugdir"
	sudo mv flashplayer.xpt "$plugdir"
	sudo rm -rdf *
fi 

if [[ ! -h /Library/Internet\ Plug-Ins/Flash\ Player.plugin ]]; then
	echo $PW | sudo -S ln -s "$plugdir"Flash\ Player.plugin /Library/Internet\ Plug-Ins/
    echo $PW | sudo -S ln -s "$plugdir"flashplayer.xpt /Library/Internet\ Plug-Ins/  
fi

### COREAUDIOKIT ####
if [[ `egrep -ic "180092" "/System/Library/Frameworks/CoreAudioKit.framework/Versions/Current/Resources/version.plist"` != "1" || $force == "reinstall" ]]; then
	echo "Downloading COREAUDIOKIT: 93KB"
	wget http://www.green-light.ca/cmn_external/app/boxee/beta/CoreAudioKit.framework.zip
	echo "Installing COREAUDIOKIT"
	sudo unzip CoreAudioKit.framework.zip
	rm CoreAudioKit.framework.zip
	sudo cp -r CoreAudioKit.framework/ /System/Library/Frameworks/CoreAudioKit.framework
	sudo chown -R root:wheel /System/Library/Frameworks/CoreAudioKit.framework/
fi

### Boxee Beta App ###
if [[ -d /Users/frontrow/Applications/Boxee.app && ! -d /Users/frontrow/Applications/Boxee.old.app ]]; then
	sudo mv /Users/frontrow/Applications/Boxee.app /Users/frontrow/Applications/Boxee.old.app
	sudo mv /Users/frontrow/Library/Application\ Support/BOXEE /Users/frontrow/Library/Application\ Support/BOXEE.old
fi
if [[ -d /Applications/Boxee.app && ! -d /Users/frontrow/Applications/Boxee.old-user.app ]]; then
	sudo mv /Applications/Boxee.app /Users/frontrow/Applications/Boxee.old-user.app
	sudo mv /Library/Application\ Support/BOXEE /Users/frontrow/Library/Application\ Support/BOXEE.old-user
fi
if [ -f "$DISKIMAGE" ]; then
	echo "Found a local Boxee image, using instead local, not looking for newer copies"
	ln -s "$DISKIMAGE" boxee-users.dmg
else
	echo "Downloading Boxee Beta"
	wget http://www.green-light.ca/cmn_external/app/boxee/beta/latest
fi

echo -e "Installing Boxee"
sudo hdiutil mount boxee-*.dmg
sudo ln -s /Volumes/boxee-* /Volumes/boxee
pax -r -z -f /Volumes/boxee/boxee-*.mpkg/Contents/Packages/boxee.pkg/Contents/Archive.pax.gz
sudo rm -rf /Applications/Boxee.app
sudo mv Boxee.app /Applications/
sudo hdiutil unmount /Volumes/boxee-*/
sudo rm /Volumes/boxee
rm boxee-*.dmg

cd ..
sudo rm -rdf $filedir
sudo chmod -R 755 /Users/frontrow/Library/Internet\ Plug-Ins
sudo chown -R frontrow:frontrow /Users/frontrow/Library/Internet\ Plug-Ins
echo "Installation successful Finished!"
exit 0

