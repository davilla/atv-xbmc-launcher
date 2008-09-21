//
//  XBMCController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 13.09.08.
//  Copyright 2008 Stephan Diederich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>
@class XBMCClientWrapper;
@interface XBMCController : BRController {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	
	NSTask* task; //task for xbmc. is needed as a member, as we check status later
	NSString* mp_app_path; //which app to launch
	XBMCClientWrapper* mp_xbmclient;
	BOOL m_enable_xbmcclient; //set to true so that menu events get sent to XBMC instead of this controller
	NSTimer* timer;
	id mp_stack;
}

- (id) initWithPath:(NSString*) f_path;
- (void) checkTaskStatus:(NSNotification *)note;
@end
