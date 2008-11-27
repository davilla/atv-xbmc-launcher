//
//  MultiFinder.h
//  atv-xbmc-tools
//
//  Created by Stephan Diederich on 11/26/08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <atvxbmccommon.h>


//keys for preferences
extern NSString* const kMFDefaultApp;
extern NSString* const kMFDefaultAppIRMode;

typedef enum{
  MFAPP_IR_MODE_NONE = 0,
  MFAPP_IR_MODE_NORMAL,
  MFAPP_IR_MODE_UNIVERSAL
} eMultiFinderAppIRMode;

@interface MultiFinder : NSObject {
  NSTask* mp_task; //the application that is currently running
  NSString* mp_next_app_to_launch; //when the currently running app quits, this one is started next
  eMultiFinderAppIRMode m_next_app_ir_mode; //launchApplication uses this to start ir_helper and to determine options
  NSString* mp_default_app; //app to launch on startup
  eMultiFinderAppIRMode m_default_app_ir_mode; //what ir for default app?
  
  NSTask* mp_ir_helper;         // here ir_helper-task is stored if it's running
  NSString* mp_ir_helper_path;  // path to launch ir_helper from
}

- (BOOL) launchApplication:(NSString*) f_app_path;
- (void) startApplicationRequest:(NSNotification *)notification;

@end
