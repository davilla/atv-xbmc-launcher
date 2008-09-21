//
//  XBMCUpdateController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 20.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "XBMCUpdateController.h"
#import "XBMCDebugHelpers.h"

@implementation XBMCUpdateController


- (id) init {
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCUpdateController with initWithURL" userInfo:nil];
	return nil;
}


- (id) initWithURL:(NSURL*) fp_url {
	PRINT_SIGNATURE();
	if( ! [super init])
		return nil;
	mp_url = [fp_url retain];
	return self;
}

- (void) dealloc {
	PRINT_SIGNATURE();
	[mp_url release];
	[mp_updates release];
	[mp_items release]; 
	[super dealloc];
}

- (void) willbePushed {
}

- (void) wasPushed {	
	[super setListTitle: @"XBMCUpdater"];
	[super setPrimaryInfoText: @"Available Downloads:"];

	//this simple test worked, so we'll reuse this one I think
	//[[self stack] swapController: [[QuDownloadController alloc] init]];
	NSString *error;
	NSPropertyListFormat format;
	NSData* plistdata = [NSData dataWithContentsOfURL: mp_url];
	mp_updates = [[NSPropertyListSerialization propertyListFromData:plistdata
																					 mutabilityOption:NSPropertyListImmutable
																										 format:&format
																								errorDescription:&error] retain];
	if(!mp_updates)
	{
    NSLog(error);
    [error release];
		[[self stack] swapController: [BRAlertController alertOfType:0 titled:nil primaryText:@"Update URLs not found or corrupt!" 
																									 secondaryText:[NSString stringWithFormat:@" %@", mp_url]]];
	} 
	mp_items = [[NSMutableArray alloc] initWithObjects:nil]; 
	unsigned int i;
	for(i=0; i < [mp_updates count]; ++i){
		id item = [BRTextMenuItemLayer menuItem];
		NSDictionary* dict = [mp_updates objectAtIndex:i];
		[item setTitle:[dict valueForKey:@"Name"]];
		[item setRightJustifiedText:[dict valueForKey:@"Type"]];
		[mp_items addObject:item];
	}
	//set ourselves as datasource for the updater list
	[[self list] setDatasource: self];
	[super wasPushed];
}

- (void)itemSelected:(long)index {
	PRINT_SIGNATURE();
	//get the dict for this update
	NSDictionary* dict = [mp_updates objectAtIndex:index];
	NSString* type = [dict valueForKey:@"Type"];
	if( [type isEqualToString:@"Application"] ){
		NSLog(@"Starting download of Application %@ from URL %@", [dict valueForKey:@"Name"], [dict valueForKey:@"URL"]);
	} else if( [type isEqualToString:@"Skin"] ){
		NSLog(@"Starting download of skin %@ from URL %@", [dict valueForKey:@"Name"], [dict valueForKey:@"URL"]);
	} else {
		NSLog(@"Unsupported update type %@", type);
	}
}

- (float)heightForRow:(long)row				{	return 0.0f; }
- (BOOL)rowSelectable:(long)row				{	return YES;}
- (long)itemCount							{	return (long) [mp_items count];}
- (id)itemForRow:(long)row					{	return [mp_items objectAtIndex:row]; }
- (long)rowForTitle:(id)title				{	return (long)[mp_items indexOfObject:title]; }
- (id)titleForRow:(long)row					{	return [[mp_items objectAtIndex:row] title]; }

@end
