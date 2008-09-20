//
//  XBMCUpdateController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 20.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "XBMCUpdateController.h"
#import "QuDownloadController.h"

@implementation XBMCUpdateController


- (id) init {
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCUpdateController with initWithURL" userInfo:nil];
	return nil;
}


- (id) initWithURL:(NSURL*) fp_url {
	if( ! [super initWithType:0 titled:@"" 
		 primaryText:@"Updater for is XBMC coming soon..." 
		 secondaryText:[NSString stringWithFormat:@"URL: %@", fp_url]] )
		return nil;
	mp_url = [fp_url retain];
	return self;
}

- (void) dealloc {
	[mp_url release];
	[super dealloc];
}

- (void) wasPushed {
	//this simple test worked, so we'll reuse this one I think
	//[[self stack] swapController: [[QuDownloadController alloc] init]];
}

@end
