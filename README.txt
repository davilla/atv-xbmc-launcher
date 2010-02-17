## XBMCLauncher Readme
September 24, 2008
Copyright (c) 2008 Stephan Diederich / Team-XBMC

see http://atv-xbmc-launcher.googlecode.com for details

## Release Notes
### 3.2.3
- fixed bug in determining the output filename for downloads which
  resulted in beeing unable to using the downloader any further
- minor cleanups in logging

### 3.2.2
- added support for new aluminium remote's Play button

### 3.2.1
- fixed version detect code for 2.3.1 and 2.4

### 3.2
- fixed: ATV 3.0 compatibility (thanks |bile|!)
- changed: download and settings are not centered anymore

### 3.1
- added: read additional download urls from NSUserDefaults key is XBMCAdditionalDownloadPlistURLs (r660)
- fixed: key-repeat for left/right (r643, r649 thx Guibaa!)
- fixed: md5 check failed for zipped downloads (r656)

### 3.0
- combined 0.x and 2.x series
- added learned remotes
- added multiple update sources
- fixed universal remote
- fixed welcome movie with MultiFinder
- changed: use MultiFinder in Launcher's bundle instead of copying to /Applications
- few gui tweaks

### 2.2
- fixed IR issues with ATV's < r2.3
- added optional arguments for applications to launch
- fixed HDMI disconnect issues for XBMC

### 2.1
- switched to MultiFinder for application switching
- fixes blackscreen issues on launching
- unified versioning. Launcher's version is used for MF, xbmchelper,...
- added "Toggle Boot App" in settings (enable XBMCExpertMode in Launcher's plist)
- renamed update to download
- renamed XBMC/BoxeeLauncher to Launcher

### 0.8
- fixes for ATV 2.3 (launching XBMC does only work ~50% of the time)
- addded universal mode support
- enable/disable auto-update in settings

### 0.6
- fixed issue #8 (screensaver kick in breaks download of update)
- fixed currentworkingdirectory which prevented xbmc's preflight script from running

### 0.5
- fixed name clash problems with SoftwareMenu (QuDownloader)
- fixed a bug where screensaver was not reenabled

### 0.4
- added multiple download possibility for updates
- fixed about box

### 0.3
- fixed issues with XBMC not getting keyboard input (Thanks ericIII!)
- added version number in About dialog
- respect XBMC's wish to restart
- changed appleremote behaviour
- removed unneeded settings

### 0.2
- fixed IR Handling for ATV 2.2
- added self-update
- combined XBMC/Boxee launcher
- fixed issues with Boxee launching
- added About including license

### 0.1
first testing version released

## License

XBMCLaucher is licensed under GPL 3.  The full license can be found in LICENSE.txt.
 
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

