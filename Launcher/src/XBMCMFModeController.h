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
#import <AppControllerProtocol.h>

@class XBMCClientWrapper;

@interface XBMCMFModeController : BRController <AppControllerProtocol> {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	
	NSString* mp_app_path; //which app to launch
    NSArray* mp_args; //arguments for application launch
	NSString* mp_launch_agent_file_name; //filename of a LaunchAgent in ~/Library/LaunchAgents
}

- (id) initWithAppPath:(NSString*) appPath   //path to app to launch
             arguments:(NSArray*) args        //arguments for that app
        userDictionary:(NSDictionary*) dict; //additional info's given

@end
