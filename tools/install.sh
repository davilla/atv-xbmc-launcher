#!/bin/bash
#
# Installer script for MultiFinder @VERSION@ via Makeself.
# original version written for ATVFiles by ericIII from atvfiles.googlecode.com

SRCDIR="$PWD"
COMMAND="${1:-install}"
PREFIX="${2:-}"

LAUNCHER_DEST="${PREFIX}/System/Library/CoreServices/Finder.app/Contents/PlugIns"
LAUNCHER_NAME="XBMCLauncher.frappliance"
ARCHIVE_NAME="@ARCHIVE_NAME@"
MULTIFINDER_NAME="MultiFinder.app"
MULTIFINDER_DEST="/Applications"

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
  echo "== Resetting loginwindow to Finder"
  sudo defaults delete /Library/Preferences/com.apple.loginwindow Finder
  echo "== Removing $LAUNCHER_NAME"
  /bin/rm -rf "$LAUNCHER_DEST/$LAUNCHER_NAME" || echo "Unable to uninstall $LAUNCHER_NAME"

  echo "$LAUNCHER_NAME successfully uninstalled."
  echo "== Removing $MULTIFINDER_NAME"
  /bin/rm -rf "$MULTIFINDER_DEST/$MULTIFINDER_NAME" || die "Unable to uninstall $MULTIFINDER_NAME"
  
  echo "$MULTIFINDER_NAME successfully uninstalled."
  echo
  if [ "$PREFIX" = "" ]; then
    echo "Loginwindow must be restarted in order to complete the installation."
    echo
    echo -n "Would you like to do this now? (Y/n) "
    read -e restartfinder
    if [[ "$restartfinder" == "" || "$restartfinder" == "Y" || "$restartfinder" == "y" ]]; then
      echo
      echo "== Restarting loginwindow"
	  kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
      kill `ps awx | grep [F]inder | awk '{print $1}'`
    fi
  fi
elif [ "$COMMAND" = "help" ]; then
  echo "Usage: $0 [action] [prefix]"
  echo
  echo "Install $MULTIFINDER_NAME @VERSION@ package, optionally to a prefix"
  echo
  echo "Where action is:"
  echo "  install       Install $MULTIFINDER_NAME"
  echo "  uninstall     Uninstall $MULTIFINDER_NAME"
  echo
  echo "prefix is the root to a mounted install.  If specified, install will be automated"
  echo "and will not restart Finder."
elif [ "$COMMAND" = "install" ]; then
  /usr/bin/ditto -k -x --rsrc "$SRCDIR/@ARCHIVE_NAME@" . || die "Unable to extract $SRCDIR/@ARCHIVE_NAME@"
  echo "== Installing $LAUNCHER_NAME"  
  echo "n" | ./*.run || die "Unable to install $LAUNCHER_NAME"

  echo "== Installing $MULTIFINDER_NAME"  
  mv MultiFinder.app "$MULTIFINDER_DEST/"
  /usr/sbin/chown -R root:admin "$MULTIFINDER_DEST/$MULTIFINDER_NAME"
  /bin/chmod -R 755 "$MULTIFINDER_DEST/$MULTIFINDER_NAME"
  /bin/chmod +s "$MULTIFINDER_DEST/$MULTIFINDER_NAME/Contents/Resources/SettingsHelper"
  echo "$MULTIFINDER_NAME successfully installed."
  echo
  # now change loginwindow
  echo "== Setting loginwindow to MultiFinder"
  sudo defaults write /Library/Preferences/com.apple.loginwindow Finder /Applications/MultiFinder.app
  # Prompt to restart finder
  if [ "$PREFIX" = "" ]; then
    echo "Loginwindow must be restarted in order to complete the installation."
    echo
    echo -n "Would you like to do this now? (Y/n) "
    read -e restartfinder
    if [[ "$restartfinder" == "" || "$restartfinder" == "Y" || "$restartfinder" == "y" ]]; then
      echo
      echo "== Restarting loginwindow"
	  kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
      kill `ps awx | grep [F]inder | awk '{print $1}'`
    fi
  fi # prefix empty
fi

# remount root as we found it
if [ "$REMOUNT" = "1" ]; then
  /sbin/mount -ur /
fi

