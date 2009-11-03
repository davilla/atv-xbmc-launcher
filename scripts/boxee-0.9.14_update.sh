#!/bin/sh

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

  # handle any pre-install items here
  echo $PW | sudo -S rm -rf "/Applications/Boxee.app/Contents/Resources/Boxee/skin"

  # install Boxee app
  echo $PW | sudo -S hdiutil attach $DISKIMAGE 

  #remove old app
  echo $PW | sudo -S rm -r /Applications/Boxee.app
  echo $PW | sudo -S rm -r /Users/frontrow/Applications/Boxee.app

  #copy new one
  mkdir -p /Users/frontrow/Applications
  cp -r /Volumes/Boxee/Boxee.app /Users/frontrow/Applications/

  echo $PW | sudo -S hdiutil detach /Volumes/Boxee

  #symlink to /Applications
  echo $PW | sudo -S ln -s /Users/frontrow/Applications/Boxee.app /Applications/

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
  
  if [ ! -d /Users/frontrow/Library/Logs ]; then
    echo $PW | sudo -S mkdir -p /Users/frontrow/Library/Logs
    echo $PW | sudo -S chown frontrow:frontrow /Users/frontrow/Library/Logs
  fi

  if [ ! -d "/Users/frontrow/Library/Application Support/BOXEE/userdata/" ]; then
  	mkdir -p "/Users/frontrow/Library/Application Support/BOXEE/userdata/"
  fi

  #add advancedsettings for better h.264 experience
  AVDSETTINGS_PATH="/Users/frontrow/Library/Application Support/XBMC/userdata/advancedsettings.xml"
  if [ ! -e "$AVDSETTINGS_PATH" ]; then
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

  echo $PW | sudo -S chown -R frontrow "/Users/frontrow/Library/Application Support/BOXEE"
  if [ -e "/Users/frontrow/Library/Application Support/Remote Buddy" ]; then
    echo $PW | sudo -S chown -R frontrow "/Users/frontrow/Library/Application Support/Remote Buddy"
  fi
  
  #delete xbmchelper it's not used on ATV
  if [ -e /Users/frontrow/Applications/Boxee.app/Contents/Resources/Boxee/bin/boxeeservice ]; then
  	echo $PW | sudo -S rm /Users/frontrow/Applications/Boxee.app/Contents/Resources/Boxee/bin/boxeeservice 
  fi

  # clean up
  
  #sync to disk, just in case...
  /bin/sync

  # restore OSBoot read/write settings
  if [ "$REMOUNT" = "1" ]; then
    echo $PW | sudo -S /sbin/mount -ur /
  fi

  # handle any post-install items here
  echo $PW | sudo -S chown -R frontrow:frontrow "/Applications/Boxee.app"
  echo $PW | sudo -S chown -R frontrow:frontrow "/Users/frontrow/Applications/Boxee.app"
  echo $PW | sudo -S chown -R frontrow:frontrow "/Users/frontrow/Library/Application Support/BOXEE"

  # remove old keymap
  /bin/rm -f "/Users/frontrow/Library/Application Support/BOXEE/UserData/Keymap.xml"

  # Update sources
  /Applications/Boxee.app/Contents/MacOS/Boxee -usf
  sed -i"" -e 's/port>9770/port>9777/g' "/Users/frontrow/Library/Application Support/BOXEE/UserData/guisettings.xml"
  sed -i"" -e 's/rendermethod>2/rendermethod>1/g' "/Users/frontrow/Library/Application Support/BOXEE/UserData/guisettings.xml"
  sed -i"" -e 's/rendermethod>3/rendermethod>1/g' "/Users/frontrow/Library/Application Support/BOXEE/UserData/guisettings.xml"
  sed -i"" -e 's/rendermethod>0/rendermethod>1/g' "/Users/frontrow/Library/Application Support/BOXEE/UserData/guisettings.xml"
  /bin/rm -rf /Users/frontrow/Applications/Boxee.app/Contents/Resources/Boxee/system/players/flashplayer/xulrunner/bin/plugins/MRJPlugin.plugin

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

