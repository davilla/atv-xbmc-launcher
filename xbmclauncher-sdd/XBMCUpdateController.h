//
//  XBMCUpdateController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 20.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

@interface XBMCUpdateController : BRCenteredMenuController {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	NSURL * mp_url; //url where to get udaters plist from
	NSMutableArray* mp_items; //list items
	NSMutableArray*	mp_updates; //list with entries what updates/downloads we offer 
}
- (id) initWithURL:(NSURL*) fp_url;
@end
