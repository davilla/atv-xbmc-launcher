#!/bin/bash

# setMultiFinderMode.sh
# xbmclauncher
#
# Created by Stephan Diederich on 02/2009.
# Copyright 2009 University Heidelberg. All rights reserved.
PASSWD=frontrow

MULTIFINDER_SOURCE=/System/Library/CoreServices/Finder.app/Contents/Plugins/XBMCLauncher.frappliance/Contents/Resources/MultiFinder.app
MULTIFINDER_TARGET=/Applications/MultiFinder.app
case $1 in
OFF)
  #should we delete MultiFinder.app here?
  echo "Resetting loginwindow" 
  echo $PASSWD | sudo -S sh -c "/usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow Finder"
  # restart loginwindow
  echo "Restarting loginwindow" 
  kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
  kill `ps awwx | grep [F]inder | grep -v setMultFinderMode | awk '{print $1}'`
  ;;
ON)
  # do some sanity checks here.
  # does MultiFinder.app exist
  if [ ! -d "$MULTIFINDER_SOURCE" ]; then
   echo "MultiFinder.app not found in $MULTIFINDER_SOURCE. Bailing out..."
   exit 1
  fi
  #remove old one
  echo "Removing old $MULTIFINDER_TARGET (if present)"
  echo $PASSWD | sudo -S rm -r "$MULTIFINDER_TARGET"
  # copy it
  echo "Copying new from from $MULTIFINDER_SOURCE to $MULTIFINDER_TARGET"
  echo $PASSWD | sudo -S sh -c "/bin/cp -r \"$MULTIFINDER_SOURCE\" \"$MULTIFINDER_TARGET\""
  echo $PASSWD | sudo -S chown -R root:admin "$MULTIFINDER_SOURCE"
  if [ ! -d "$MULTIFINDER_TARGET" ]; then
   echo "Copying failed. MultiFinder.app not found in $MULTIFINDER_TARGET. Bailing out..."
   exit 2
  fi
  #set as default app on boot
  echo "Setting loginwindow to $MULTIFINDER_TARGET" 
  echo $PASSWD | sudo -S sh -c "/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow Finder $MULTIFINDER_TARGET"
  # restart loginwindow
  echo "Restarting loginwindow" 
  kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
  kill `ps awwx | grep [F]inder | grep -v setMultFinderMode | awk '{print $1}'`
  ;;
*)
  echo "USAGE: setMultiFinderMode.sh {ON|OFF}"
  echo "ON: enables MultiFinder by copying from XBMCLauncher.frappliance and exchanging Finder in loginwindow's plist"
  echo "OFF: deletes 'Finder' key in loginwindow's plist"
  ;;
esac



