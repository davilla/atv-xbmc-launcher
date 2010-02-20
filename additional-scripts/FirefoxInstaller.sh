#!/bin/sh
# Script to install Firefox on ATV from Launcher --> Downloads Menu
# Modified from default Launcher install scripts by Jim Wiley 2010

DISKIMAGE=$1

echo "Installing from diskimage $DISKIMAGE"
# check that disk-image exists
if [ -e "$DISKIMAGE" ]; then
  PW="frontrow"

  # check and store OSBoot read/write settings
  REMOUNT=0
  # Check if / is mounted read only
  if mount | grep ' on / '  | grep -q 'read-only'; then
    REMOUNT=1
    echo $PW | sudo -S /sbin/mount -uw /
  fi

  # Remove existing Firefox Install if found in either /Applications or ~/Applications
  if [[ -d /Users/frontrow/Library/Applications/Firefox.app  ]]; then
	echo $PW | sudo -S rm -rf /Users/frontrow/Library/Applications/Firefox.app
  fi
  
  if [[ -d /Applications/Firefox.app  ]]; then
  	echo $PW | sudo -S rm -rf /Applications/Firefox.app
  fi
  
  # install Firefox in ~/Applications - / partition is getting crowded now
  # that Boxee needs to reside in /Applications to run properly
  
  echo $PW | sudo -S echo "Y" | hdiutil attach "$DISKIMAGE" 
  echo $PW | sudo -S cp -r /Volumes/Firefox/Firefox.app /Users/frontrow/Applications/ 
  echo $PW | sudo -S hdiutil detach /Volumes/Firefox/

  #sync to disk, just in case...
  /bin/sync
  
  # clean up
  echo $PW | sudo -S rm /Users/frontrow/Movies/Install\ Flash\ Player\ 10\ UB
 
  # restore OSBoot read/write settings
  if [ "$REMOUNT" = "1" ]; then
    echo $PW | sudo -S /sbin/mount -ur /
  fi


  exit 0
fi

echo "Failed to find diskimage $DISKIMAGE"
exit -1
