#!/bin/sh

DISKIMAGE=$1
KEYMAP=$2

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

  # install xbmc app
  echo $PW | sudo -S hdiutil attach $DISKIMAGE 
  echo $PW | sudo -S installer -pkg /Volumes/XBMC/"XBMC Media Center.mpkg" -target /
  echo $PW | sudo -S hdiutil detach /Volumes/XBMC

  # handle any post-install items here
  # perl to bash convertion of postflight script pending
  if [ ! -d /Users/frontrow/Movies ]; then
    echo $PW | sudo -S mkdir /Users/frontrow/Movies
    echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Movies
  fi
  if [ ! -d "/Users/frontrow/Video Playlists" ]; then
    echo $PW | sudo -S mkdir "/Users/frontrow/Video Playlists"
    echo $PW | sudo -S chown frontrow:frontrow "/Users/frontrow/Video Playlists"
  fi
  if [ ! -d /Users/frontrow/Music ]; then
    echo $PW | sudo -S mkdir /Users/frontrow/Music
    echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Music
  fi
  if [ ! -d "/Users/frontrow/Music Playlists" ]; then
    echo $PW | sudo -S mkdir "/Users/frontrow/Music Playlists"
    echo $PW | sudo -S chown frontrow:frontrow "/Users/frontrow/Music Playlists"
  fi
  if [ ! -d /Users/frontrow/Pictures ]; then
    echo $PW | sudo -S mkdir /Users/frontrow/Pictures
    echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Pictures
  fi

  if [ ! -d "/Users/frontrow/Library/Application Support/XBMC/userdata/" ]; then
  	mkdir -p "/Users/frontrow/Library/Application Support/XBMC/userdata/"
  fi

  #copy new Keymap.xml if present (means launcher >= 0.4 update)
  if [ -e "$KEYMAP" ]; then
    #copy it to app folder, so userdata can be wiped
    if [ -d "/Applications/XBMC.app/Contents/Resources/XBMC/system/" ]; then
      echo $PW | sudo -S cp "$KEYMAP" "/Applications/XBMC.app/Contents/Resources/XBMC/system/Keymap.xml"
	else
	  echo "Ouch, something went wrong here. /Applications/XBMC.app/Contents/Resources/XBMC/system/ not present after XBMC install"
    fi
  fi

  #add advancedsettings for better h.264 experience
  AVDSETTINGS_PATH="/Users/frontrow/Library/Application Support/XBMC/userdata/advancedsettings.xml"
  if [ ! -e "$AVDSETTINGS_PATH" ]; then
  	echo "<advancedsettings><skiploopfilter>48</skiploopfilter></advancedsettings>" >> "$AVDSETTINGS_PATH"
  else
  	#fix typo that was present up to r212
	sed -e s/sliploopfilter/skiploopfilter/g -i "" "$AVDSETTINGS_PATH"
  fi

  #d4rk said this is already done in installer; do it anyway, can't hurt
  echo $PW | sudo -S chown -R frontrow "/Users/frontrow/Library/Application Support/XBMC"
  echo $PW | sudo -S chown -R frontrow "/Users/frontrow/Library/Application Support/Remote Buddy"
  
  #delete xbmchelper in beta2 as is crashs on startup 
  if [ -e /Applications/XBMC.app/Contents/Resources/XBMC/XBMCHelper ]; then
  	echo $PW | sudo -S rm /Applications/XBMC.app/Contents/Resources/XBMC/XBMCHelper
  fi
  # clean up
  # fixme -> the below is not correct for a symlink
  #if [ -e /Users/frontrow/Movies/XBMC ]; then
  	# something makes this symlink during install so zap it.
  	echo $PW | sudo -S rm /Users/frontrow/Movies/XBMC
  #fi
  
  #sync to disk, just in case...
  /bin/sync

  # restore OSBoot read/write settings
  if [ "$REMOUNT" = "1" ]; then
    echo $PW | sudo -S /sbin/mount -ur /
  fi

  exit 0
fi

echo "Failed to find diskimage $DISKIMAGE"
exit -1
