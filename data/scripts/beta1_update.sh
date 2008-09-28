#!/bin/sh

DISKIMAGE=$1

echo "Installing from diskimage $DISKIMAGE"
# check that disk-image exists
if [ -e $DISKIMAGE ]; then
 PW="frontrow"

 #TODO check and store read/write

 # install xbmc app
 echo $PW | sudo -S hdiutil attach $DISKIMAGE 
 echo $PW | sudo -S installer -pkg /Volumes/XBMC/"XBMC Media Center.mpkg" -target /
 echo $PW | sudo -S hdiutil detach /Volumes/XBMC

 # handle any post-install items here

 #TODO
 #restore read/write settings
 
 # clean up
 # echo $PW | sudo -S rm -rf /Users/Frontrow/staging/xbmc
 exit 0
fi
echo "Failed to find diskimage $DISKIMAGE"
exit -1
