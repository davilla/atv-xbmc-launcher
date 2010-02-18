#!/bin/bash
#-------------------------------------------------------------------
# BASH Script for Apple TV to Install rBboxee. 
# Requires: SSH
# based on the great work by JimWiley & hillbilly1980
#-------------------------------------------------------------------
#
DISKIMAGE=$1
PW="frontrow"

echo $PW | sudo -S mount -uw /
filedir=/Users/frontrow/BoxeeBetaInstall/
appdir=/Users/frontrow/Applications/
plugdir=/Library/Internet\ Plug-Ins/

force=""

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
	
### FLASH PLUGIN ####
if [[ ( `egrep -ic "10.0.42.34" "/Library/Internet Plug-Ins/Flash Player.plugin/Contents/Info.plist"` != "1" || $force == "reinstall" ) && $force != "latest" ]]; then
	echo "Downloading Flash Plugin: 5.4MB"
	wget http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_osx_ub.dmg
	echo "Installing Flash Plugin"
	sudo hdiutil mount install_flash_player_osx_ub.dmg
	pax -r -z -f /Volumes/Install\ Flash\ Player\ 10\ UB/Adobe\ Flash\ Player.pkg/Contents/Archive.pax.gz
	sudo hdiutil unmount /Volumes/Install\ Flash\ Player\ 10\ UB/
	rm -Rd Flash\ Player.plugin/Contents/Resources/{c,d,f,i,j,k,n,p,r,s,t,z}*.lproj
	sudo rm -rf "$plugdir"Flash\ Player.plugin
	sudo mv Flash\ Player.plugin/ "$plugdir"Flash\ Player.plugin
	sudo rm -rdf * 
fi 

if [[ `egrep -ic "10.1.51.66" "/Library/Internet Plug-Ins/Flash Player.plugin/Contents/Info.plist"` != "1" && $force == "latest" ]]; then
	echo "Downloading Flash Plugin Beta: 5.4MB"
	wget http://download.macromedia.com/pub/labs/flashplayer10/flashplayer10_1_p2_mac_121709.dmg
	echo "Installing Flash Plugin"
	sudo hdiutil mount flashplayer10_1_p2_mac_121709.dmg
	pax -r -z -f /Volumes/Install\ Flash\ Player\ 10\ UB/Adobe\ Flash\ Player.pkg/Contents/Archive.pax.gz
	sudo hdiutil unmount /Volumes/Install\ Flash\ Player\ 10\ UB/
	sudo rm -rf "$plugdir"Flash\ Player.plugin
	sudo mv Flash\ Player.plugin/ "$plugdir"Flash\ Player.plugin
	sudo rm -rdf * 
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
sudo chmod -R 755 /Library/Internet\ Plug-Ins/
sudo chown -R root:wheel /Library/Internet\ Plug-Ins/
echo "Installation successful Finished!"
exit 0

