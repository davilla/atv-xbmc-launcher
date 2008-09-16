//
//  XBMCController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 13.09.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

@interface XBMCController : BRAlertController {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	NSTask *task; //task for xbmc. is needed as a member, as we check status later
	NSString * path; //which xbmc to launch
}

-(id) initWithPath:(NSString*) f_path;
-(void)checkTaskStatus:(NSNotification *)note;
@end
