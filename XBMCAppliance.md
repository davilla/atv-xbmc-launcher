# Introduction #

Main controller which presents the entry in ATVs main menu and the following menu on the right.

Code:
[XBMCAppliance.h](http://code.google.com/p/atv-xbmc-launcher/source/browse/trunk/xbmclauncher/XBMCAppliance.h)
[XBMCAppliance.m](http://code.google.com/p/atv-xbmc-launcher/source/browse/trunk/xbmclauncher/XBMCAppliance.m)

# Details #

## Branding ##
TODO: add details about how to brand right hand menu entries and the left hand main entry

## Menu items ##
XBMCAppliance reads its menu entries from the FRApplianceCategoryDescriptors Array in Info.plist. Currently there are 2 types of entries distinguished by
```
<key>entry-type</key>
<integer>0</integer>
```
The entry-type is mapped to
```
typedef enum {
	APPLICATION = 0,
	UPDATER = 1
} eControllerType;
```
APPLICATION entries need to provide a path to launch like
```
<key>path</key>
<string>/Users/frontrow/Applications/XBMC.app/Contents/MacOS/XBMC</string>
```
UPDATER entries need to provide an URL where to download a plist which customizes the updater entries
```
<key>URL</key>
<string>http://atv-xbmc-launcher.googlecode.com/svn/trunk/data/update_urls.plist</string>
```

Depending on the menu entry selected, one on the controllers [XBMCController](XBMCController.md) or [XBMCUpdater](XBMCUpdater.md) is launched with the path / URL