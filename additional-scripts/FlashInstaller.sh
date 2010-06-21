#!/bin/bash
# Flash 10.0 Installer Script for atv-xbmc-launcher 
# Jim Wiley 2010 - modified from Launcher default install scripts 

DISKIMAGE=$1
PW="frontrow"
plugdir=/Library/Internet\ Plug-Ins/

echo "Installing from diskimage $DISKIMAGE"

# check that disk-image exists

if [ -e $DISKIMAGE ]; then

  # check and store OSBoot read/write settings
  REMOUNT=0
  # Check if / is mounted read only
  if mount | grep ' on / '  | grep -q 'read-only'; then
    REMOUNT=1
    echo $PW | sudo -S /sbin/mount -uw /
  fi


### Create Plugin DIr if it does not exist ###
  echo $PW | sudo -S mkdir -p "$plugdir"



  ### UNINSTALL PREVIOUS FLASH VERSIONS ###
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
  
    
  ### INSTALL FLASH PLUGIN ###  
  echo $PW | sudo -S hdiutil attach $DISKIMAGE 
  echo "DYLD_FRAMEWORK_PATH='/System/Library/Frameworks/OSXFrames' installer -pkg /Volumes/Flash\ Player/Install\ Adobe\ Flash\ Player.app/Contents/Resources/Adobe\ Flash\ Player.pkg -target /" | sudo -s
  echo "exit"
  echo $PW | sudo -S hdiutil detach /Volumes/Flash\ Player

  #sync to disk, just in case...
  /bin/sync
  
  # clean up
  echo $PW | sudo -S rm /Users/frontrow/Movies/Flash\ Player
 

  # restore OSBoot read/write settings
  if [ "$REMOUNT" = "1" ]; then
    echo $PW | sudo -S /sbin/mount -ur /
  fi


  exit 0
fi

echo "Failed to find diskimage $DISKIMAGE"
exit -1
