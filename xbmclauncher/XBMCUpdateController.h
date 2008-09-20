//
//  XBMCUpdateController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 20.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

@interface XBMCUpdateController : BRAlertController {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	NSURL * mp_url;
}

- (id) initWithURL:(NSURL*) fp_url;
@end
