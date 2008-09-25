//	XBMCUserDefaults.m
//
//	based on 
//  BundleUserDefaults.m
//
//  Created by John Chang on 6/15/07.
//  This code is Creative Commons Public Domain.  You may use it for any purpose whatsoever.
//  http://creativecommons.org/licenses/publicdomain/
//

#import "XBMCUserDefaults.h"

NSString* const XBMC_USE_INTERNAL_IR = @"UseInternalIR";

@implementation XBMCUserDefaults

- (id) initWithPersistentDomainName:(NSString *)domainName
{
	if ((self = [super init]))
	{
		_applicationID = [domainName copy];
		_registrationDictionary = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	}
	return self;
}

+(NSUserDefaults *) defaults
{
	static XBMCUserDefaults* sl_defaults = nil;
	if( ! sl_defaults )
		sl_defaults = [[self alloc] initWithPersistentDomainName:@"com.teamxbmc.xbmclauncher"];
	return sl_defaults;
	
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_applicationID release];
	[_registrationDictionary release];
	[super dealloc];
}


- (void) _applicationWillTerminate:(NSNotification *)notification
{
	[self synchronize];
}


- (id)objectForKey:(NSString *)defaultName
{
	id value = [(id)CFPreferencesCopyAppValue((CFStringRef)defaultName, (CFStringRef)_applicationID) autorelease];
	if (value == nil)
		value = [_registrationDictionary objectForKey:defaultName];
	return value;
}

- (void)setObject:(id)value forKey:(NSString *)defaultName
{
	CFPreferencesSetAppValue((CFStringRef)defaultName, (CFPropertyListRef)value, (CFStringRef)_applicationID);
}

- (void)removeObjectForKey:(NSString *)defaultName
{
	CFPreferencesSetAppValue((CFStringRef)defaultName, NULL, (CFStringRef)_applicationID);
}


- (void)registerDefaults:(NSDictionary *)registrationDictionary
{
	[_registrationDictionary release];
	_registrationDictionary = [registrationDictionary retain];
}


- (BOOL)synchronize
{
	return CFPreferencesSynchronize((CFStringRef)_applicationID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

@end
