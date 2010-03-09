//
//  GenericPluginModeController.h
//  atv-xbmc-tools
//
//  Created by Stephan Diederich on 08.03.10.
//  Copyright 2010 Stephan Diederich. All rights reserved.
//

#import <BackRow/BackRow.h>
#import "AppControllerProtocol.h"

//convenient class that is intented to be subclassed for apps that need 
//special handling (like passing controller events etc)
@interface GenericPluginModeController : BRController <AppControllerProtocol> {
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
  
  int _screensaverTimeout;

	NSTask* _task;               // the app we launched
  NSString* _applicationPath;  // path of app to launch
  NSArray* _args;              // arguments for application launch

  NSDictionary* _userInfo;  
}

- (id) initWithAppPath:(NSString*) appPath
             arguments:(NSArray*) args
        userDictionary:(NSDictionary*) userDictionary;

//overwrite methods below to provide custom behaviour
- (void) controlWasActivated;
- (void) controlWasDeactivated;

//overwrite to do custom stuff after app-launch
- (void) applicationDidLaunch;
//overwrite to be notified of application exit
//by default this just pops the controller of the stack
- (void) applicationDidExitWithCode:(int) exitCode;

#pragma mark -
#pragma mark private methods
// are already called by stack-methods above
- (void) disableScreenSaver;
- (void) enableScreenSaver;

- (void) enableRendering;
- (void) disableRendering;

//sets the running app (==_task) as frontprocess
- (void) setAppToFrontProcess;

//launches the app 
-(void) startAppAndAttachListener;
//is called if app exits
- (void)checkTaskStatus:(NSNotification *)note;
@end
