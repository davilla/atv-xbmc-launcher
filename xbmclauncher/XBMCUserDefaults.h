//	XBMCUserDefaults.h
//
//	based on:
//  BundleUserDefaults.h
//
//  Created by John Chang on 6/15/07.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import <Cocoa/Cocoa.h>

//define keys for lookup in preferences

extern NSString* const XBMC_USE_INTERNAL_IR; //NSBool

@interface XBMCUserDefaults : NSUserDefaults {
	NSString * _applicationID;
	NSDictionary * _registrationDictionary;
}

+ (NSUserDefaults* ) defaults;

@end


@interface NSUserDefaultsController (SetDefaults)
- (void) _setDefaults:(NSUserDefaults *)defaults;
@end
