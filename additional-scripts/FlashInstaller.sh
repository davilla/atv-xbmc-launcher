#!/bin/sh
# Flash 10.0 Installer Script for atv-xbmc-launcher 
# Jim Wiley 2010 - modified from Launcher default install scripts 

DISKIMAGE=$1
PW="frontrow"
plugdir=/Users/frontrow/Library/Internet\ Plug-Ins/

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
  echo $PW | sudo -S pax -r -z -f /Volumes/Install\ Flash\ Player\ 10\ UB/Adobe\ Flash\ Player.pkg/Contents/Resources/Adobe\ Flash\ Player.pax.gz
  echo $PW | sudo -S rm -Rd Flash\ Player.plugin/Contents/Resources/{c,d,f,i,j,k,n,p,r,s,t,z,e}*.lproj
  echo $PW | sudo -S mv Flash\ Player.plugin/ "$plugdir"
  echo $PW | sudo -S mv flashplayer.xpt "$plugdir"
  echo $PW | sudo -S chown -R frontrow:frontrow "$plugdir"
  
 
  echo $PW | sudo -S ln -s "$plugdir"Flash\ Player.plugin /Library/Internet\ Plug-Ins/
  echo $PW | sudo -S ln -s "$plugdir"flashplayer.xpt /Library/Internet\ Plug-Ins/  
   

  echo $PW | sudo -S hdiutil detach /Volumes/Install\ Flash\ Player\ 10\ UB/

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
