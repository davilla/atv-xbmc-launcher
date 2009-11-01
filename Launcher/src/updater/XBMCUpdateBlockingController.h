//
//  XBMCUpdateBlockingController.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 29.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

@protocol XBMCUpdateBlockingControllerDelegate;
@interface XBMCUpdateBlockingController : 	BRTextWithSpinnerController {
	int padding[16];
	NSTask* mp_update_task;
  id<XBMCUpdateBlockingControllerDelegate> delegate;
}

//initialize object with path to update script and an array with parameters
// once this controller is visible on the screen, it starts running the script
// and reports back to its delegate
- (id) initWithScript:(NSString*) fp_script_path downloads:(NSArray*) fp_update_paths;

- (void) setDelegate:(id) aDelegate;
- (id) delegate;

@end


@protocol XBMCUpdateBlockingControllerDelegate

- (void) xBMCUpdateBlockingControllerDidSucceed:(XBMCUpdateBlockingController *) theUpdater;
- (void) xBMCUpdateBlockingController:(XBMCUpdateBlockingController *) theUpdater didFailWithExitCode:(int) exitCode;

@end