//
//  BoxeeUpdateBlockingController.h
//  BoxeeLauncher
//
//  Created by Stephan Diederich on 29.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

//starts the update and blocks until it's finished then pops itself away
@interface BoxeeUpdateBlockingController : 	BRAlertController {
	int padding[16];
	NSTask* mp_update_task;
}

- (id) initWithScript:(NSString*) fp_script_path forUpdate:(NSString*) fp_update_path;
- (void) updateFinished:(NSNotification *)note;

@end
