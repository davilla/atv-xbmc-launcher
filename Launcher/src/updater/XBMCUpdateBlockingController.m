//
//  XBMCUpdateBlockingController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 29.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "XBMCUpdateBlockingController.h"
#import "XBMCDebugHelpers.h"

@implementation XBMCUpdateBlockingController

- (id) initWithScript:(NSString*) fp_script_path downloads:(NSArray*) fp_update_paths {
	PRINT_SIGNATURE();
	if( ! [super initWithTitle:@"Updater" text:[NSString stringWithFormat:@"Running %@...", [fp_script_path lastPathComponent]]])
		return nil;
	
	mp_update_task = [[NSTask alloc] init];
	
	[mp_update_task setLaunchPath:@"/bin/bash"];
  NSMutableArray* arguments = [NSMutableArray arrayWithObject:fp_script_path];
  [arguments addObjectsFromArray:fp_update_paths];
	[mp_update_task setArguments: arguments];
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(updateFinished:)
																							 name:NSTaskDidTerminateNotification
																						 object:mp_update_task];
	return self;
}

-(void) dealloc
{
	PRINT_SIGNATURE();
	[super dealloc];
}


- (void) setDelegate:(id) aDelegate {
  delegate = aDelegate;
}
- (id) delegate {
  return delegate;
}

- (void)updateFinished:(NSNotification *)note
{
	PRINT_SIGNATURE();
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	int status = [[note object] terminationStatus];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mp_update_task release];
	mp_update_task = nil;
	if (status != 0)
    [delegate xBMCUpdateBlockingController:self didFailWithExitCode: status];
	else
    [delegate xBMCUpdateBlockingControllerDidSucceed:self];
  [pool release];
}


#pragma mark -
#pragma mark stack callbacks
-(void) controlWasActivated
{
	PRINT_SIGNATURE();
	[super controlWasActivated];
	[mp_update_task launch];
}

#pragma mark -
#pragma mark button events
- (BOOL)brEventAction:(BREvent *)event
{
	PRINT_SIGNATURE();
	//while the update is running, don't do anything
	if( mp_update_task &&  [mp_update_task isRunning] )
		return YES;
	else
		return [super brEventAction:event];
}

@end