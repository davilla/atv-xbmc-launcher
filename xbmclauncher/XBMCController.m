//
//  XBMCController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 13.09.08.
//  Copyright 2008 Stephan Diederich. All rights reserved.
/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "XBMCController.h"
@class BRLayerController;

@implementation XBMCController

-(id) initWithPath:(NSString*) f_path
{
	path=f_path;
	[path retain]; 
	NSLog(@"init XBMCController");
	
	return [super initWithType:0 titled:@"Launching XBMC..." primaryText:@"Info"
							 secondaryText:@"This screen will stay here until XBMC closes and should then go to the background. To restart XBMC use the menu"];

}

- (void)dealloc
{
	NSLog(@"deallocating...");
	[path release];
	[super dealloc];
}

- (void)controlWasActivated
{
	NSLog(@"controlWasActivated");
	[super controlWasActivated];
}

- (void)checkTaskStatus:(NSNotification *)note
{
	NSLog(@"checkTaskStatus");
	if (! [task isRunning])
	{
		NSLog(@"task stopped!");
	
		// Return code for XBMC
		int status = [[note object] terminationStatus];
	
		// release the old task, as a new one gets created (if
		[task release];
		task = nil;
		
		// Show frontrow menu 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
																												object:[BRDisplayManager sharedInstance]];
		[[BRDisplayManager sharedInstance] captureAllDisplays];
		
		if (status != 0)
		{
			[self setTitle:@"Error"];
			[self setPrimaryText:[NSString stringWithFormat:@"XBMC exited With Status: %i",status]];
			[self setSecondaryText:nil];
			//now we need to kill XBMCHelper!
			//TODO for now we use a script as I don't know how to kill a Task with OSX API. any hints are pretty welcome!
			NSString* killer_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"killxbmchelper" ofType:@"sh"];
			NSTask* killer = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments: [NSArray arrayWithObject:killer_path]];
			[killer waitUntilExit];
		} else {
			[self setTitle:@"XBMC exited gracefully"];
			[self setPrimaryText:@"Use the menu to restart it"];
			[self setSecondaryText:nil];
			[[self stack] popController];
			//check memory management here, there seems to be a bug. I'd say that retainCount should be zero here, as we were swapped
			//and are in the autorelease pool. What's wrong? All that swapping, pushing and popping?
			//NSLog([NSString stringWithFormat:@"Current retain count: %i", [self retainCount]]);
		}
	} else {
		//Task is still running. How come?!
		NSLog(@"Task still running. This is definately a bug :/");
		[self setTitle:@"Error"];
		[self setPrimaryText:@"XBMC Task is still running. This is a bug, please report it."];
		[self setSecondaryText:nil];
	}
} 

- (void) willBePushed
{
	// We're about to be placed on screen, but we're not yet there
	// always call super
	NSLog(@"willbePushed");
	[super willBePushed];
}

- (void) wasPushed
{
	NSLog(@"wasPushed");
	// We've just been put on screen, the user can see this controller's content now	
	//Hide frontrow menu this seems not to be needed for 2.1. XBMC is aggressive enough...
	//reenabled to test in 2.02
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerStopRenderingNotification"
																											object:[BRDisplayManager sharedInstance]];
	[[BRDisplayManager sharedInstance] releaseAllDisplays];
	//start xbmc
	task = [[NSTask alloc] init];
	@try {
		[task setLaunchPath: path];
		//[task setArguments:[NSArray arrayWithObjects:@"-fs",nil]]; fullscreen seems to be ignored...
		[task launch];
	} 
	@catch (NSException* e) {
		// Show frontrow menu 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
																												object:[BRDisplayManager sharedInstance]];
		[[BRDisplayManager sharedInstance] captureAllDisplays];
		[self setTitle:@"Error"];
		[self setPrimaryText:@"Cannot launch XBMC. Path tried was:"];
		[self setSecondaryText:path];
		return [super wasPushed];
	}
	//wait a bit for task to start
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
	[NSThread sleepUntilDate:future];
	//attach our listener
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(checkTaskStatus:)
																							 name:NSTaskDidTerminateNotification
																						 object:task];
	
/*
  // tell backrow to quit rendering
  [[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerStopRenderingNotification" object:[BRDisplayManager sharedInstance]];
  
  // grab display
  [[BRDisplayManager sharedInstance] releaseAllDisplays];
  
  // run app and wait for exit
	task = [[NSTask alloc] init];
	[task setLaunchPath: @"/Users/frontrow/Applications/XBMC.app/Contents/MacOS/XBMC"];
	@try {
		[task launch];
	} 
	@catch (NSException* e) {
		BRAlertController *alert = [BRAlertController alertOfType:0
																											 titled:@"Error"
																									primaryText:@"Cannot launch XBMC"
																								secondaryText:@"Please make sure you have XBMC.app installed in /Users/frontrow/Applications/"];
		[[self stack] swapController:alert];
	}
	
  [task waitUntilExit];
  
  // give backrow back the display
  [[BRDisplayManager sharedInstance] captureAllDisplays];
  // tell backrow to resume rendering
  [[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification" object:[BRDisplayManager sharedInstance]];
	*/
	// always call super
	[super wasPushed];
}

- (void) willBePopped
{
	// The user pressed Menu, but we've not been removed from the screen yet
	NSLog(@"willbepopped");
	// always call super
	[super willBePopped];
}

- (void) wasPopped
{
	// The user pressed Menu, removing us from the screen
	NSLog(@"wasPopped");
	// always call super
	[super wasPopped];
}

- (void) willBeBuried
{
	// The user just chose an option, and we will be taken off the screen
	NSLog(@"willbeBuried");
	// always call super
	[super willBeBuried];
}

- (void) wasBuriedByPushingController: (BRLayerController *) controller
{
	// The user chose an option and this controller os no longer on screen
	NSLog(@"wasburiedbypushing");
	// always call super
	[super wasBuriedByPushingController: controller];
}

- (void) willBeExhumed
{
	// the user pressed Menu, but we've not been revealed yet
	NSLog(@"willbeexhumed");
	// always call super
	[super willBeExhumed];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
	// handle being revealed when the user presses Menu
	NSLog(@"wasExhumedByPopping");
	// always call super
	[super wasExhumedByPoppingController: controller];
}

@end
