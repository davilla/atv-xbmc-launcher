#!/bin/sh

INSTALLER=$1
PW="frontrow"
REMOUNT=0
XBMC_USERDATA="/Users/frontrow/Library/Application Support/XBMC/userdata/"

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

 #backup old Keymap.xml if it exists
 if [ -e "$XBMC_USERDATA/Keymap.xml" ]; then
 	mv "$XBMC_USERDATA/Keymap.xml" "$XBMC_USERDATA/Keymap.xml.bak"
 fi
 
 #download new Keymap.xml and replace old one
 wget http://atv-xbmc-launcher.googlecode.com/svn/tags/xbmc-info/data/Keymap.xml -O "$XBMC_USERDATA/Keymap.xml"
 
 #remove the download
 rm $INSTALLER 

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

