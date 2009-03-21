//
//  XBMCUpdateBlockingController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 29.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

//starts the update and blocks until it's finished then pops itself away
@interface XBMCUpdateBlockingController : 	BRTextWithSpinnerController {
	int padding[16];
	NSTask* mp_update_task;
}

- (id) initWithScript:(NSString*) fp_script_path downloads:(NSArray*) fp_update_paths;
- (void) updateFinished:(NSNotification *)note;

@end
