#!/bin/sh

DISKIMAGE=$1
PW="frontrow"
REMOUNT=0

echo "Installing from diskimage $DISKIMAGE"

# make sure we're running as root, if not relaunch us
if [ "$USER" != "root" ]; then
  echo $PW | sudo -S "$0" $*
  exit 0
fi

# check that disk-image exists
if [ -e $DISKIMAGE ]; then

 # Check if / is mounted read only
 if mount | grep ' on / '  | grep -q 'read-only'; then
  REMOUNT=1
  /sbin/mount -uw /
 fi
 
 # install xbmc app
 hdiutil attach $DISKIMAGE 
 installer -pkg /Volumes/XBMC/"XBMC Media Center.mpkg" -target /
 hdiutil detach /Volumes/XBMC

 # handle any post-install items here

 # remount root as we found it
 if [ "$REMOUNT" = "1" ]; then
  /sbin/mount -ur /
 fi
 
 # clean up

 exit 0
fi
echo "Failed to find diskimage $DISKIMAGE"
exit -1
