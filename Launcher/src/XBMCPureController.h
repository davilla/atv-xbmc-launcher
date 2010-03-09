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
#import "XBMCUserDefaults.h"
#import "AppControllerProtocol.h"

@class XBMCClientWrapper;

typedef enum {
  CONTROLLER_EVENT_START_STATE,
  CONTROLLER_EVENT_STATE_1,
  CONTROLLER_EVENT_STATE_2,
  CONTROLLER_EVENT_STATE_3
} eControllerEventState;

@interface XBMCPureController : BRController <AppControllerProtocol> {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	
	NSTask* mp_task; //task for xbmc. is needed as a member, as we check status later
	NSString* mp_app_path; //which app to launch
    NSArray* mp_args; //arguments for application launch
	NSString* mp_helper_path; //which helper to disable/enable/kill on error
	NSString* mp_launch_agent_file_name; //filename of a LaunchAgent in ~/Library/LaunchAgents
	BOOL m_xbmc_running;  //true while xbmc is running
	XBMCClientWrapper* mp_xbmclient; // our own event-client implementation
	NSTimer* mp_swatter_timer; //timer used in helperapp-swatting
	int m_screen_saver_timeout;
	NSDate* mp_controller_event_timestamp; //timestamp to check for controller event
	eControllerEventState m_controller_event_state;
}

- (id) initWithAppPath:(NSString*) appPath
             arguments:(NSArray*) args
        userDictionary:(NSDictionary*) userDictionary;
@end
