#!/bin/sh

INSTALLER=$1
PW="frontrow"
REMOUNT=0

echo "Installing file $INSTALLER"

# check that disk-image exists
if [ -e $INSTALLER ]; then

 # Check if / is mounted read only
 if mount | grep ' on / '  | grep -q 'read-only'; then
  REMOUNT=1
  echo $PW | sudo -S /sbin/mount -uw /
 fi

 #delete boxeelauncher 0.1 if present
 echo $PW | sudo -S rm -rf /System/Library/CoreServices/Finder.app/Contents/PlugIns/BoxeeLauncher.frappliance
 
 #install new launcher
 echo $PW | sudo -S chmod +x $INSTALLER
 echo $PW | sudo -S $INSTALLER -- install /
  
 #remove the download
 rm $INSTALLER 

  #add advancedsettings for better h.264 experience
  AVDSETTINGS_PATH="/Users/frontrow/Library/Application Support/XBMC/userdata/advancedsettings.xml"
  if [ ! -e "$AVDSETTINGS_PATH" ]; then
  	mkdir -p "/Users/frontrow/Library/Application Support/XBMC/userdata/"
  	echo "<advancedsettings><skiploopfilter>8</skiploopfilter><osx_gl_fullscreen>true</osx_gl_fullscreen></advancedsettings>" >> "$AVDSETTINGS_PATH"
  else
  	#fix typo that was present up to r212
	sed -e s/sliploopfilter/skiploopfilter/g -i "" "$AVDSETTINGS_PATH"
	#update with osx_gl_fullscreen
	#check if its there
	grep -q osx_gl_fullscreen "$AVDSETTINGS_PATH"
	if [ $? -eq 0 ]; then 
		echo "osx_gl_fullscreen present in advancedsettings.xml"
	else
		echo "osx_gl_fullscreen not present, adding it to advancedsettings.xml"
		sed -e s#\</advancedsettings\>#\<osx_gl_fullscreen\>true\</osx_gl_fullscreen\>\</advancedsettings\>#g -i "" "$AVDSETTINGS_PATH"
	fi
  fi

 #sync to disk, just in case...
 /bin/sync
 
 # remount root as we found it
 if [ "$REMOUNT" = "1" ]; then
  echo $PW | sudo -S /sbin/mount -ur /
 fi

 # restart finder
 kill `ps awx | grep [F]inder | awk '{print $1}'`
 
 exit 0
fi
echo "Failed to find installer $INSTALLER"
exit -1

