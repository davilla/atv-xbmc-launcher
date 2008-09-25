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
#import <XBMCPreferencesController.h>

@class XBMCClientWrapper;

@interface XBMCController : BRController {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	
	NSTask* mp_task; //task for xbmc. is needed as a member, as we check status later
	NSString* mp_app_path; //which app to launch
	BOOL m_xbmc_running; 
	XBMCClientWrapper* mp_xbmclient;
	eIRControlType m_ir_control_type; //read from preferences
	BOOL m_universal_remote; //read from preferences. if true and m_control_type == IR_INTERNAL_XBMCHELPER 
													 // XBMCHelper is started in universal remote mode
}

- (id) initWithPath:(NSString*) f_path;
- (void) checkTaskStatus:(NSNotification *)note;
@end
