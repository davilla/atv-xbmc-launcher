//
//  MultiFinder.h
//  atv-xbmc-tools
//
//  Created by Stephan Diederich on 11/26/08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <atvxbmccommon.h>

//keys for preferences
extern NSString* const kMFDefaultApp;
extern NSString* const kMFDefaultAppIRMode;

//typedef for MultiFinder's FSM states
typedef enum{
  MF_STATE_UNINITIALIZED = 0,
  MF_STATE_SAFE_MODE, //something went wrong, so we only do finder launching
  MF_STATE_DEFAULT_APP, //default app is running (on startup or when user app exited)
  MF_STATE_USER_APP,
} eMFState;

@interface MultiFinder : NSObject {
  NSTask* mp_task;      // the application that is currently running
  NSTask* mp_ir_helper; // here ir_helper-task is stored if it's running
    
  NSString* mp_next_app_to_launch;          // launchApplication consumes this (and releases it)
  eMultiFinderAppIRMode m_next_app_ir_mode; // launchApplication uses this to start ir_helper and to determine options

  NSString* mp_ir_helper_path;  // path to launch ir_helper from
  eMFState m_state;             // MF is implemented as a state machine and this holds the current state
  
  NSArray* mp_black_list;       //list of apps that are blacklisted and which executable is checked against whitelist
  NSMutableArray* mp_white_list;//list of allowed executables to start (mostly those MultiFinder launched)
  EventHandlerRef m_carbonEventsRef;
}

@end
