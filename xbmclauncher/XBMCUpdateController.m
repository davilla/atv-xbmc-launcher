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
	[mp_header release];
	[mp_update_urls_plist release];
	[mp_updates release];
	[super dealloc];
}

- (void) willbePushed {

}

- (void) wasPushed {	
	//this simple test worked, so we'll reuse this one I think
	//[[self stack] swapController: [[QuDownloadController alloc] init]];
	NSString *error;
	NSPropertyListFormat format;
	NSData* plistdata = [NSData dataWithContentsOfURL: mp_url];
	[plistdata writeToFile:@"/Users/frontrow/test.plist" atomically:true];
	mp_update_urls_plist = [NSPropertyListSerialization propertyListFromData:plistdata
																					 mutabilityOption:NSPropertyListImmutable
																										 format:&format
																					 errorDescription:&error];
	if(!mp_update_urls_plist)
	{
    NSLog(error);
    [error release];
		[[self stack] swapController: [BRAlertController alertOfType:0 titled:nil primaryText:@"Update URLs not found or corrupt!" 
																									 secondaryText:[NSString stringWithFormat:@" %@", mp_url]]];
	} 
	//draw gui
	mp_header = [[BRHeaderControl alloc] init];
	NSRect masterframe = [self frame];
	NSRect frame = masterframe;
	// header goes in a specific location
	frame.origin.y = frame.size.height * 0.82f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
	[mp_header setFrame: frame];
	[mp_header setTitle:@"XBMCUpdater"];	
	[self addControl:mp_header];
		
/*
	//draw a selection list of something to 	
	mp_updates = [[BRListControl alloc] init]; 
	[mp_updates setProvider:self];
	frame.size.width = masterframe.size.width *0.5;
	frame.size.height = masterframe.size.height *0.7;
	frame.origin.x = 0; 
	frame.origin.y = 0;
	[mp_updates setFrame: frame];
	[self addControl:mp_updates];	

*/
	
	[super wasPushed];
}

- (int) dataCount
{
	PRINT_SIGNATURE();
	return 1;
}

- (id) dataAtIndex:(int) rowIndex
{
	PRINT_SIGNATURE();
	NSLog(@"rowIndex.. %i", rowIndex);
	return [NSString stringWithFormat:@"Test %i", rowIndex] ;
}

-(BOOL) respondsToSelector:(SEL)aSelector{
	NSString * methodName = NSStringFromSelector(aSelector);
	NSLog(@"respondsToSelector %@", methodName);
	return [super respondsToSelector:aSelector];
}


@end
