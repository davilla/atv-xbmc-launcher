//
//  MultiFinder.h
//  atv-xbmc-tools
//
//  Created by Stephan Diederich on 11/26/08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MultiFinder : NSObject {
  NSTask* mp_task; //the application that is currently running
  NSString* mp_next_app_to_launch; //when the currently running app quits, this one is started next
  BOOL m_app_needs_ir; //if true, launchApplication should also start our IR daemon for mp_next_app_to_launch
  NSString* mp_default_app; //app to launch on startup
  BOOL m_default_app_needs_ir; //does default app need ir?
  
  NSTask* mp_ir_helper;         // here ir_helper-task is stored if it's running
  NSString* mp_ir_helper_path;  // path to launch ir_helper from
}

- (BOOL) launchApplication:(NSString*) f_app_path;
- (void) startApplicationRequest:(NSNotification *)notification;

@end
