//
//  XBMCPreferencesController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 25.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "XBMCPreferencesController.h"
#import "XBMCUserDefaults.h"
#import "XBMCDebugHelpers.h"

@implementation XBMCPreferencesController

- (float)heightForRow:(long)row				{	return 0.0f; }
- (BOOL)rowSelectable:(long)row				{	return YES;}
- (long)itemCount							{	return (long) [mp_items count];}
- (id)itemForRow:(long)row					{	return [mp_items objectAtIndex:row]; }
- (long)rowForTitle:(id)title				{	return (long)[mp_items indexOfObject:title]; }
- (id)titleForRow:(long)row					{	return [[mp_items objectAtIndex:row] title]; }

- (id) init{
	PRINT_SIGNATURE();
	if( ! [super init])
		return nil;
	return self;
}

- (void) dealloc {
	PRINT_SIGNATURE();
	[mp_items release]; 
	[super dealloc];
}

- (void) willbePushed {
}

- (void) wasPushed {	
	[super setListTitle: @"XBMCLauncher"];
	[super setPrimaryInfoText:@"Settings"];
	
	mp_items = [[NSMutableArray alloc] initWithObjects:nil]; 
	id item = [BRTextMenuItemLayer menuItem];
	[item setTitle:@"Use Internal Remote Control"];
	[item setRightJustifiedText:[[XBMCUserDefaults defaults] boolForKey:XBMC_USE_INTERNAL_IR] ? @"Yes": @"No"];
	[mp_items addObject:item];
	
	//set ourselves as datasource for the updater list
	[[self list] setDatasource: self];
	[super wasPushed];
}

- (void)itemSelected:(long)index {
	PRINT_SIGNATURE();
	//hack! TODO: if there are more items, do proper selection handling with index 
	if(index == 0){
		int val = [[XBMCUserDefaults defaults] boolForKey:XBMC_USE_INTERNAL_IR];
		[[XBMCUserDefaults defaults] setBool:!val forKey:XBMC_USE_INTERNAL_IR];
		[[XBMCUserDefaults defaults] synchronize];
		[[self itemForRow:index] setRightJustifiedText:[[XBMCUserDefaults defaults] boolForKey:XBMC_USE_INTERNAL_IR] ? @"Yes": @"No"];
	} else {
		ELOG(@"Huh? Item is not in list :/");
	}
	[[self list] reload];
}

@end
