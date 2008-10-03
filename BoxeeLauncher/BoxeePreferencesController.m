//
//  BoxeePreferencesController.m
//  BoxeeLauncher
//
//  Created by Stephan Diederich on 25.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "BoxeePreferencesController.h"
#import "BoxeeUserDefaults.h"
#import "BoxeeDebugHelpers.h"

@implementation BoxeePreferencesController

- (float)heightForRow:(long)row				{	return 0.0f; }
- (BOOL)rowSelectable:(long)row				{	return YES;	}
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
	[super setListTitle: @"Boxee Launcher"];
	[super setPrimaryInfoText:@"Settings"];
	[self recreateMenuList];
	//set ourselves as datasource for the updater list
	[[self list] setDatasource: self];
	[super wasPushed];
}

- (void)itemSelected:(long)index {
	PRINT_SIGNATURE();
	//hack! TODO: if there are more items, do proper selection handling with index 
	if(index == 0){
		int val = [[BoxeeUserDefaults defaults] boolForKey:Boxee_USE_INTERNAL_IR];
		[[BoxeeUserDefaults defaults] setBool:!val forKey:Boxee_USE_INTERNAL_IR];
		[[BoxeeUserDefaults defaults] synchronize];
		[[self itemForRow:index] setRightJustifiedText:[[BoxeeUserDefaults defaults] boolForKey:Boxee_USE_INTERNAL_IR] ? @"Yes": @"No"];
		[self recreateMenuList];
	}
	else if (index == 1){
		int val = [[BoxeeUserDefaults defaults] boolForKey:Boxee_USE_UNIVERSAL_REMOTE];
		[[BoxeeUserDefaults defaults] setBool:!val forKey:Boxee_USE_UNIVERSAL_REMOTE];
		[[BoxeeUserDefaults defaults] synchronize];
		[[self itemForRow:index] setRightJustifiedText:[[BoxeeUserDefaults defaults] boolForKey:Boxee_USE_UNIVERSAL_REMOTE] ? @"Yes": @"No"];
	} else {
		ELOG(@"Huh? Item is not in list :/");
	}
	[[self list] reload];
}

- (void) recreateMenuList
{
	if(!mp_items){
		mp_items = [[NSMutableArray alloc] initWithObjects:nil]; 
	} else {
		[mp_items removeAllObjects];
	}
	id item = [BRTextMenuItemLayer menuItem];
	[item setTitle:@"Use Internal Remote Control"];
	[item setRightJustifiedText:[[BoxeeUserDefaults defaults] boolForKey:Boxee_USE_INTERNAL_IR] ? @"Yes": @"No"];
	[mp_items addObject:item];
	if( ! [[BoxeeUserDefaults defaults] boolForKey:Boxee_USE_INTERNAL_IR] ){
		item = [BRTextMenuItemLayer menuItem];
		[item setTitle:@"Use Boxee's Universal Mode"];
		[item setRightJustifiedText:[[BoxeeUserDefaults defaults] boolForKey:Boxee_USE_UNIVERSAL_REMOTE] ? @"Yes": @"No"];
		[mp_items addObject:item];
	}
}
@end
