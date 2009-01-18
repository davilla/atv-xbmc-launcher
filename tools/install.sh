#!/bin/bash
#
# Installer script for XBMCLauncher @VERSION@ via Makeself.
# original version written for ATVFiles by ericIII from atvfiles.googlecode.com

SRCDIR="$PWD"
COMMAND="${1:-install}"
PREFIX="${2:-}"

LAUNCHER_DEST="${PREFIX}/System/Library/CoreServices/Finder.app/Contents/PlugIns"
LAUNCHER_NAME="XBMCLauncher.frappliance"
ARCHIVE_NAME="@ARCHIVE_NAME@"

die() {
  echo $*
  exit 1
}

# make sure we're running as root, if not relaunch us
if [ "$USER" != "root" ]; then
  echo "This installer must be run as root."
  echo
  echo "Please enter your password below to authorize as root."
  echo "In most cases, this password is \"frontrow\"."
  sudo "$0" $*
  exit 0
fi

REMOUNT=0

# Check if / is mounted read only
if mount | grep ' on / '  | grep -q 'read-only'; then
  REMOUNT=1
  /sbin/mount -uw /
fi

if [ "$COMMAND" = "uninstall" ]; then
  echo "== Removing $LAUNCHER_NAME"
  /bin/rm -rf "$LAUNCHER_DEST/$LAUNCHER_NAME" || die "Unable to uninstall $LAUNCHER_NAME"

  echo "$LAUNCHER_NAME successfully uninstalled."
  echo
  echo "Finder must be restarted in order to complete the installation."
elif [ "$COMMAND" = "help" ]; then
  echo "Usage: $0 [action] [prefix]"
  echo
  echo "Install $LAUNCHER_NAME @VERSION@, optionally to a prefix"
  echo
  echo "Where action is:"
  echo "  install       Install $LAUNCHER_NAME"
  echo "  uninstall     Uninstall $LAUNCHER_NAME"
  echo
  echo "prefix is the root to a mounted install.  If specified, install will be automated"
  echo "and will not restart Finder."
elif [ "$COMMAND" = "install" ]; then
  
  # move old frappliance existing out of way
  if [ -d "$LAUNCHER_DEST/$LAUNCHER_NAME" ]; then
    echo "== Removing old $LAUNCHER_NAME"
    /bin/rm -rf "$LAUNCHER_DEST/$LAUNCHER_NAME" || die "Unable to remove old $LAUNCHER_NAME"
  fi

  echo "== Extracting $LAUNCHER_NAME"
  /usr/bin/ditto -k -x --rsrc "$SRCDIR/@ARCHIVE_NAME@" "$LAUNCHER_DEST" || die "Unable to install $LAUNCHER_NAME"
  /usr/sbin/chown -R root:wheel "$LAUNCHER_DEST/$LAUNCHER_NAME"
  /bin/chmod -R 755 "$LAUNCHER_DEST/$LAUNCHER_NAME"
  
  echo "$LAUNCHER_NAME successfully installed."
  echo

  # Prompt to restart finder
  if [ "$PREFIX" = "" ]; then
    echo "Finder must be restarted in order to complete the installation."
    echo
    echo -n "Would you like to do this now? (Y/n) "
    read -e restartfinder
    if [[ "$restartfinder" == "" || "$restartfinder" == "Y" || "$restartfinder" == "y" ]]; then
      echo
      echo "== Restarting Finder"

      kill `ps awx | grep [F]inder | awk '{print $1}'`
    fi
  fi # prefix empty
elif [ "$COMMAND" = "installrestart" ]; then
  
  # move old frappliance existing out of way
  if [ -d "$LAUNCHER_DEST/$LAUNCHER_NAME" ]; then
    echo "== Removing old $LAUNCHER_NAME"
    /bin/rm -rf "$LAUNCHER_DEST/$LAUNCHER_NAME" || die "Unable to remove old $LAUNCHER_NAME"
  fi

  echo "== Extracting $LAUNCHER_NAME"
  /usr/bin/ditto -k -x --rsrc "$SRCDIR/@ARCHIVE_NAME@" "$LAUNCHER_DEST" || die "Unable to install $LAUNCHER_NAME"
  /usr/sbin/chown -R root:wheel "$LAUNCHER_DEST/$LAUNCHER_NAME"
  /bin/chmod -R 755 "$LAUNCHER_DEST/$LAUNCHER_NAME"
  
  echo "$LAUNCHER_NAME successfully installed."
  echo

	kill `ps awx | grep [F]inder | awk '{print $1}'`
fi

# remount root as we found it
if [ "$REMOUNT" = "1" ]; then
  /sbin/mount -ur /
fi

