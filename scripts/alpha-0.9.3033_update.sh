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

  # install xbmc app
  echo $PW | sudo -S hdiutil attach $DISKIMAGE 
  echo $PW | sudo -S installer -pkg /Volumes/boxee-tiger3/boxee-tiger3.mpkg -target /
  echo $PW | sudo -S hdiutil detach /Volumes/boxee-tiger3

  # handle any post-install items here

  # clean up
  # fixme -> the below is not correct for a symlink
  #if [ -e /Users/Frontrow/Movies/boxee-tiger3 ]; then
    # something makes this symlink during install so zap it.
    echo $PW | sudo -S rm /Users/Frontrow/Movies/boxee-tiger3
  #fi

  #delete launch.agent file. This is needed if appletv is rebooted before first Boxee launch
  rm /Users/frontrow/Library/LaunchAgents/tv.boxee.helper.plist

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
