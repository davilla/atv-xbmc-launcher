//
//  XBMCController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 13.09.08.
//  Copyright 2008 Stephan Diederich. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>
#import <XBMCUserDefaults.h>

@class XBMCClientWrapper;

@interface XBMCController : BRController {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	
	NSTask* mp_task; //task for xbmc. is needed as a member, as we check status later
	NSString* mp_app_path; //which app to launch
	NSString* mp_helper_path; //which helper to disable/enable/kill on error
	BOOL m_xbmc_running;  //true while xbmc is running
	XBMCClientWrapper* mp_xbmclient; // our own event-client implementation
	BOOL m_use_internal_ir; //read from preferences, if yes, XBMC's XBMCHelper is disabled
	NSTimer* mp_swatter_timer; //timer used in helperapp-swatting
}

- (id) initWithAppPath:(NSString*) f_app_path helperPath:(NSString*) f_helper_path;
- (void) checkTaskStatus:(NSNotification *)note; //callback when XBMC quit or crashed
- (bool) inUserSettingsSetXpath:(NSString*) f_xpath toInt:(int) f_value;
+ (bool) deleteHelperLaunchAgent;
- (void) setupHelperSwatter; //starts a NSTimer which callback periodically searches for a running mp_helper_path app and kills it
- (void) disableSwatterIfActive; //disables swatter and releases mp_swatter_timer
- (void) killHelperApp:(NSTimer*) f_timer; //kills a running instance of mp_helper_path application; f_timer can be nil, it's not used
@end
