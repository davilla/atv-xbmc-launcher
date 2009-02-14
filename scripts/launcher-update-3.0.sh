#!/bin/sh

INSTALLER=$1
PW="frontrow"
REMOUNT=0

echo "Installing file $INSTALLER"

# check that file exists
if [ -e $INSTALLER ]; then

 # Check if / is mounted read only
 if mount | grep ' on / '  | grep -q 'read-only'; then
  REMOUNT=1
  echo $PW | sudo -S /sbin/mount -uw /
 fi

 #delete boxeelauncher 0.1 if present
 echo $PW | sudo -S rm -rf /System/Library/CoreServices/Finder.app/Contents/PlugIns/BoxeeLauncher.frappliance
  
 #install MultiFinder/Launcher combo
 echo $PW | sudo -S chmod +x $INSTALLER
 echo $PW | sudo -S $INSTALLER -- install /

 #by default MultiFinder is now deactivated
 #reset default finder (MF installation sets it)
 echo $PW | sudo -S defaults delete /Library/Preferences/com.apple.loginwindow Finder
 echo "Resetted loginwindow"
 
 #remove the download
 rm $INSTALLER 

 #sync to disk, just in case...
 /bin/sync
 
 # remount root as we found it
 if [ "$REMOUNT" = "1" ]; then
  echo $PW | sudo -S /sbin/mount -ur /
 fi

 # restart loginwindow
 kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
 kill `ps awwx | grep [F]inder | grep -v launcher-update | awk '{print $1}'`
  
 exit 0
fi
echo "Failed to find installer $INSTALLER"
exit -1

