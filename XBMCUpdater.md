# Introduction #

XBMCUpdater is the main controller for updates to XBMC.
The idea is it handles updates or initial downloading of XBMC.app as well as downloads of skins/addons and to update itself.

The update source of the updater is a file stored in svn, depending on the version of Launcher a different update source it used by default.

| Launcher Version | URL |
|:-----------------|:-----|
| < 1   | http://atv-xbmc-launcher.googlecode.com/svn/tags/xbmc-info/update_urls.plist |
| 1< x < 3 |  http://atv-xbmc-launcher.googlecode.com/svn/tags/mf-info/update_urls.plist |
| >= 3 | http://atv-xbmc-launcher.googlecode.com/svn/tags/ul-info/update_urls.plist|

The file itself is a plist with an array of dictionaries where each represents an update. An array entry looks like this:
```
	<dict>
		<key>UpdateScript</key>
		<string>http://atv-xbmc-launcher.googlecode.com/svn/tags/xbmc-info/scripts/xbmc-8.10.b1_update.sh</string>
		<key>URL</key>
		<string>http://downloads.sourceforge.net/xbmc/XBMC_for_Mac-Atlantis-Beta_1.dmg</string>
		<key>Type</key>
		<string>Application</string>
		<key>MD5</key>
		<string>f18de725a61eadab19cc57a997f76c4f</string>
		<key>Name</key>
		<string>XBMC Atlantis Beta1</string>
	</dict>
```

  * Key: is the text which appears in update menu
  * Type: Is the small text which appears on lower right in update menu
  * URL: the actual update to download
  * UpdateScript: a script which is downloaded first and started after the main download as parameter
  * MD5: optional. If present, it is checked against the download.

## Multiple update sources ##
Starting from Launcher 3.0beta5 there is the possibility to have multiple update-sources. Reason for this was to provide 3rd party builds in Launcher, while still having the mainline repository available.
The url where to get update sources [changed](http://code.google.com/p/atv-xbmc-launcher/source/detail?spec=svn618&r=609) from a simple entry to an array of update sources:
```
   <key>URLs</key>
   <array>
       <string>http://atv-xbmc-launcher.googlecode.com/svn/tags/ul-info/update_urls.plist</string>
       <string>http://this-is-the-second.org/update_urls.plist</string>
   </array>
```
so to add another source, Info.plist in /System/Library/CoreServices/Finder.app/Plugins/XBMCLauncher/Contents/Info.plist must be changed by the user to include the aditional entry.

## Update Process ##
Technical details on update process:

  * (multiple) update\_urls.plist is/are downloaded
  * menu is filled with entries
When a menu item is selected:
  * download the script mentioned in UpdateScript
  * use QuDownloader to download file from URL
QuDownloader pops itself from stack, when download finished
  * if MD5 is present, check it against download, report error on mismatch
  * push XBMCUpdateBlockingController (absorbs menu press on apple remote) to start the update script with filepath of the download as parameter
  * aftert return of update script, downloaded files are deleted and the "Update finished" dialog is presented


## Credits ##
Thanks to Alan Quatermain and nito for the nice [Downloader](http://wiki.awkwardtv.org/wiki/A_Downloader_Controller)!