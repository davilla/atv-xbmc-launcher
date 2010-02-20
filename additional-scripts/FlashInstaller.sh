#!/bin/sh
# Written by Jim Wiley 2010 inspired by the atv-xbmc-launcher default Scripts
# 
# Script that takes a flash 10xxxxxx.dmg file as an input and then installs
# flash plugin on your ATV. Can be used via commandline eg:
# ./FlashInstaller.sh flashplayer10_1_p2_mac_121709.dmg
# but really designed for atv-xbmc-launcher usage.
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

  # Check if Turbo's atv_enabler or kext_enabler is loaded - necessary for Flash10.1b2
  # If we are installing flash 10.1b2 and /etc/rc.local does not contain Turbo's special 
  # magic, then abort install and tell user what they need to do
  
  if [[ `egrep -ic "Turbo" "/etc/rc.local"` != "1" && $DISKIMAGE == "flashplayer10_1_p2_mac_121709.dmg" ]]; then
		echo "$DISKIMAGE requires you to run Turbo's Kext Enabler from NitoTV Settings Menu"
		exit -1
  fi

  # Check if previous flash plugin is already installed in either /Library or ~/Library
  # If it finds it - it zaps it!
  
  if [[ -d /Users/frontrow/Library/Internet\ Plug-Ins/Flash\ Player.plugin  ]]; then
	echo $PW | sudo -S rm -rf /Users/frontrow/Library/Internet\ Plug-Ins/Flash\ Player.plugin
	echo $PW | sudo -S rm -rf /Users/frontrow/Library/Internet\ Plug-Ins/flashplayer.xpt
  fi
  if [[ -d /Library/Internet\ Plug-Ins/Flash\ Player.plugin  ]]; then
  	echo $PW | sudo -S rm -rf /Library/Internet\ Plug-Ins/Flash\ Player.plugin
  	echo $PW | sudo -S rm -rf /Library/Internet\ Plug-Ins/flashplayer.xpt
  fi
  
  
  	
  # install Flash in ~/Library/Internet Plug-Ins
  # Since Boxee now needs to reside in /Applications space on / partition
  # is at a premium. Relocating Plug-in to frontrow user directory tree to save space!
  
  echo $PW | sudo -S hdiutil attach $DISKIMAGE 
  echo $PW | sudo -S pax -r -z -f /Volumes/Install\ Flash\ Player\ 10\ UB/Adobe\ Flash\ Player.pkg/Contents/Archive.pax.gz
  echo $PW | sudo -S mv Flash\ Player.plugin/ /Users/frontrow/Library/Internet\ Plug-Ins/
  if [[ -d /Users/frontrow/Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/Resources/cs.lproj ]]; then
  	echo $PW | sudo -S rm -Rd /Users/frontrow/Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/Resources/{c,d,f,i,j,k,n,p,r,s,t,z,e}*.lproj
  fi
  echo $PW | sudo -S chown -R frontrow:frontrow /Users/frontrow/Library/Internet\ Plug-Ins/Flash\ Player.plugin
  echo $PW | sudo -S mv flashplayer.xpt /Users/frontrow/Library/Internet\ Plug-Ins/
  echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Library/Internet\ Plug-Ins/flashplayer.xpt
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
