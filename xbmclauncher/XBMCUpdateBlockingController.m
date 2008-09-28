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

- (id) initWithScript:(NSString*) fp_script_path forUpdate:(NSString*) fp_update_path {
	PRINT_SIGNATURE();
	if( ! [super initWithType:0 titled:@"Running update..."
															primaryText:@"This message will disappear when finished"
															secondaryText:@"...and maybe someone will beautify this message... :)"])
		return nil;

	mp_update_task = [[NSTask alloc] init];

	[mp_update_task setLaunchPath:@"/bin/bash"];
	[mp_update_task setArguments:[NSArray arrayWithObjects:fp_script_path,
																fp_update_path,
																nil
																]];
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

-(void) wasPushed
{
	PRINT_SIGNATURE();
	[mp_update_task launch];
	[super wasPushed];
}

- (void)updateFinished:(NSNotification *)note
{
	PRINT_SIGNATURE();
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mp_update_task release];
	mp_update_task = nil;
//	[[self stack] popController];
	[[self stack] swapController: [BRAlertController alertOfType:0 titled:@"Update finished!" primaryText:nil secondaryText:nil]];
}

- (BOOL)brEventAction:(BREvent *)event
{
	PRINT_SIGNATURE();
	//while the update is running, don't do anything
	if( [mp_update_task isRunning] )
		return YES;
	else
		return [super brEventAction:event];
}

@end