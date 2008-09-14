//
//  XBMCAppliance.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 13.09.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "XBMCAppliance.h"
#import "XBMCController.h"
@implementation XBMCAppliance

// Override to allow FrontRow to load custom appliance plugins
+ (NSString *) className {
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

- (id)controllerForIdentifier:(id)identifier {
	// normally check info.plist entries. But why for us?
	if([identifier isEqualToString:@"XBMC"]){
		return [[[XBMCController alloc] init] autorelease];
	} else if ([identifier isEqualToString:@"XBMCUpdate"]){
		// here we want to use something like BRTextWithSpinnerController to get the update running
		return [BRAlertController alertOfType:0
																	 titled:identifier
															primaryText:@"XBMC Update not implemented yet"
														secondaryText:nil];		
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
