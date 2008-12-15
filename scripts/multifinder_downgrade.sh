#!/bin/sh

INSTALLER=$1
PW="frontrow"
REMOUNT=0

 # Check if / is mounted read only
 if mount | grep ' on / '  | grep -q 'read-only'; then
  REMOUNT=1
  echo $PW | sudo -S /sbin/mount -uw /
 fi

#remove multifinder
echo $PW | sudo -S rm -rf /Applications/MultiFinder.app

#reset default finder
echo $PW | sudo -S defaults delete /Library/Preferences/com.apple.loginwindow Finder

 #install new launcher
 echo $PW | sudo -S chmod +x $INSTALLER
 echo $PW | sudo -S $INSTALLER -- install /
  
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
 kill `ps awwx | grep [F]inder | grep -v multifinder_downgrade | awk '{print $1}'`
 
 exit 0