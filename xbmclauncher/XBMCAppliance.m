//
//  XBMCAppliance.m
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

#import "XBMCAppliance.h"
#import "XBMCController.h"
#import "XBMCUpdateController.h"
#import "XBMCDebugHelpers.h"

//enable this one to get notifications to BRDisplayManger logged on command line
//#define BRDISPLAY_MANAGER_OBSERVATION 1

typedef enum {
	APPLICATION = 0,
	UPDATER = 1
} eControllerType;

@implementation XBMCAppliance
+ (void) initialize
{
	PRINT_SIGNATURE();
	Class cls = NSClassFromString( @"BRFeatureManager" );
	if ( cls == nil )
		return;
	[[cls sharedInstance] enableFeatureNamed: [[NSBundle bundleForClass: self] bundleIdentifier]];
}

// Override to allow FrontRow to load custom appliance plugins
+ (NSString *) className {
	PRINT_SIGNATURE();
	// this function creates an NSString from the contents of the
	// struct objc_class, which means using this will not call this
	// function recursively, and it'll also return the *real* class
	// name.
	NSString * className = NSStringFromClass( self );
	
	// new method based on the BackRow NSException subclass, which conveniently provides us a backtrace
	// method!
	NSRange result = [[BRBacktracingException backtrace] rangeOfString:@"(in BackRow)"];
	
	if(result.location != NSNotFound) {
		NSLog(@"+[%@ className] called for whitelist check, so I'm lying, m'kay?", className);
		className = @"RUIDVDAppliance";
	}
	return className;
}

#ifdef BRDISPLAY_MANAGER_OBSERVATION
- (void) listen:(NSNotification*) note{
	NSLog(@"-------Logged %@", [note name]);
}
#endif

- (id) init
{
	if( ![super init] )
		return nil;
#ifdef BRDISPLAY_MANAGER_OBSERVATION
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(listen:)
																							 name:nil
																						 object:[BRDisplayManager sharedInstance]];
#endif
	return self;
}
- (void) dealloc
{
#ifdef BRDISPLAY_MANAGER_OBSERVATION
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
	[super dealloc];
}

- (id)controllerForIdentifier:(id)identifier {
	// find the proper entry in categories list from Info.plist
	NSEnumerator *enumerator = [[[self applianceInfo] applianceCategoryDescriptors] objectEnumerator];
	id obj = nil;
	while((obj = [enumerator nextObject]) != nil) {
		if ([identifier isEqualToString:[obj valueForKey:@"identifier"]]){
			break;
		}
	}
	NSNumber*	entry_type = [obj valueForKey:@"entry-type"];
	//entry type is the key if this is an XBMC.app entry or something else like updater, etc
	if( [entry_type isEqualToNumber:[NSNumber numberWithInt: APPLICATION]] ){
		//there can be more than one xbmc entry in the list, e.g. to test developer version etc.
		//so read the path of current and pass to controller
		NSString* path = [obj valueForKey:@"path"];
		return [[[XBMCController alloc] initWithPath:path] autorelease];
	} 
	else if ( [entry_type isEqualToNumber:[NSNumber numberWithInt: UPDATER]] ){
		// here we want to use something like BRTextWithSpinnerController to get the update running
		NSURL* url = [NSURL URLWithString: [obj valueForKey:@"URL"]];
		return [[[XBMCUpdateController alloc] initWithURL:url] autorelease];
	} else {
		return [BRAlertController alertOfType:0
														titled:@"XBMCLauncher"
											 primaryText:@"Error"
										 secondaryText:@"Unknown menu entry. This should definately NOT happen"];
	}
}

-(id)applianceCategories {
	NSMutableArray *categories = [NSMutableArray array];
	
	NSEnumerator *enumerator = [[[self applianceInfo] applianceCategoryDescriptors] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]) != nil) {
		BRApplianceCategory *category = [BRApplianceCategory categoryWithName:[obj valueForKey:@"name"] identifier:[obj valueForKey:@"identifier"] preferredOrder:[[obj valueForKey:@"preferred-order"] floatValue]];
		[categories addObject:category];
	}
	return categories;
}

@end
