//
//  XBMCUpdateController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 20.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

@interface XBMCUpdateController : BRController {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	NSURL * mp_url;
	id	mp_update_urls_plist;
	BRHeaderControl* mp_header;
	BRListControl * mp_updates;
}
- (NSRect) frame; //just here to get it compiling. method is from some super class
- (id) initWithURL:(NSURL*) fp_url;
@end
