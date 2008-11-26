//
//  XBMCHelper.m
//  xbmchelper
//
//  Created by Stephan Diederich on 11/12/08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "XBMCHelper.h"
#import "remotecontrolwrapper/AppleRemote.h"
#import "remotecontrolwrapper/MultiClickRemoteBehavior.h"
#import <XBMCDebugHelpers.h>
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
@implementation XBMCHelper
- (id) init{
  PRINT_SIGNATURE();
  if( ![super init] ){
    return nil;
  }
  mp_wrapper = nil;
  
  // capture remote
  // 1. instantiate the desired behavior for the remote control device
  mp_remote_behavior = [[MultiClickRemoteBehavior alloc] init];	
  	
  // 2. configure the behavior
  [mp_remote_behavior setDelegate: self];
  [mp_remote_behavior setClickCountingEnabled:false];
  [mp_remote_behavior setSimulateHoldEvent:true];
  mp_remote_control = [[AppleRemote alloc] initWithDelegate: mp_remote_behavior];
  if( ! mp_remote_control ){
    NSException* myException = [NSException
                                exceptionWithName:@"AppleRemoteInitExecption"
                                reason:@"AppleRemote could not be initialized"
                                userInfo:nil];
    @throw myException;
  }
  [mp_remote_control startListening: self];
  return self;
}

- (void) dealloc{
  PRINT_SIGNATURE();
  [mp_remote_control release];
  [mp_remote_behavior release];
  [mp_wrapper release];
  [super dealloc];
}

//----------------------------------------------------------------------------
- (void) remoteButton: (RemoteControlEventIdentifier)event 
          pressedDown: (BOOL) pressedDown 
           clickCount: (unsigned int)clickCount
{
  if(m_verbose){
    NSString* pressed;
    NSString* buttonName;
    if (pressedDown) pressed = @"(pressed)"; else pressed = @"(released)";
    
    switch(event) {
      case kRemoteButtonPlus:
        buttonName = @"Volume up";			
        break;
      case kRemoteButtonMinus:
        buttonName = @"Volume down";
        break;			
      case kRemoteButtonMenu:
        buttonName = @"Menu";
        break;			
      case kRemoteButtonPlay:
        buttonName = @"Play";
        break;			
      case kRemoteButtonRight:	
        buttonName = @"Right";
        break;			
      case kRemoteButtonLeft:
        buttonName = @"Left";
        break;			
      case kRemoteButtonRight_Hold:
        buttonName = @"Right holding";	
        break;	
      case kRemoteButtonLeft_Hold:
        buttonName = @"Left holding";		
        break;			
      case kRemoteButtonPlus_Hold:
        buttonName = @"Volume up holding";	
        break;				
      case kRemoteButtonMinus_Hold:			
        buttonName = @"Volume down holding";	
        break;				
      case kRemoteButtonPlay_Hold:
        buttonName = @"Play (sleep mode)";
        break;			
      case kRemoteButtonMenu_Hold:
        buttonName = @"Menu (long)";
        break;
      case kRemoteControl_Switched:
        buttonName = @"Remote Control Switched";
        break;
      default:
        break;
    }
    NSLog(@"%@ %@", pressed, buttonName);
  }
  switch(event){
    case kRemoteButtonPlay:
      if(pressedDown) [mp_wrapper handleEvent:ATV_BUTTON_PLAY];
      break;
    case kRemoteButtonPlay_Hold:
      if(pressedDown) [mp_wrapper handleEvent:ATV_BUTTON_PLAY_H];
      break;
    case kRemoteButtonRight:
      if(pressedDown) 
        [mp_wrapper handleEvent:ATV_BUTTON_RIGHT];
      else
        [mp_wrapper handleEvent:ATV_BUTTON_RIGHT_RELEASE];
      break;
    case kRemoteButtonRight_Hold:
      if(pressedDown) [mp_wrapper handleEvent:ATV_BUTTON_RIGHT_H];
      break;
    case kRemoteButtonLeft:
      if(pressedDown) 
        [mp_wrapper handleEvent:ATV_BUTTON_LEFT];
      else
        [mp_wrapper handleEvent:ATV_BUTTON_LEFT_RELEASE];
      break;
    case kRemoteButtonLeft_Hold:
      if(pressedDown) [mp_wrapper handleEvent:ATV_BUTTON_LEFT_H];
      break;
    case kRemoteButtonPlus:
      if(pressedDown) 
        [mp_wrapper handleEvent:ATV_BUTTON_UP];
      else
        [mp_wrapper handleEvent:ATV_BUTTON_UP_RELEASE];
      break;
    case kRemoteButtonMinus:
      if(pressedDown) 
        [mp_wrapper handleEvent:ATV_BUTTON_DOWN];
      else
        [mp_wrapper handleEvent:ATV_BUTTON_DOWN_RELEASE];
      break;      
    case kRemoteButtonMenu:
      if(pressedDown) [mp_wrapper handleEvent:ATV_BUTTON_MENU];
      break;
    case kRemoteButtonMenu_Hold:
      if(pressedDown) [mp_wrapper handleEvent:ATV_BUTTON_MENU_H];
      break;    
    default:
      NSLog(@"Oha, remote button not recognized %i pressed/released %i", event, pressedDown);
  }
}

//----------------------------------------------------------------------------
- (void) connectToServer:(NSString*) fp_server withUniversalMode:(bool) f_yes_no{
 if(mp_wrapper)
   [self disconnect];
  mp_wrapper = [[XBMCClientWrapper alloc] initWithUniversalMode:f_yes_no serverAddress:fp_server];
}

//----------------------------------------------------------------------------
- (void) disconnect{
  [mp_wrapper release];
  mp_wrapper = nil;
}

//----------------------------------------------------------------------------
- (void) enableVerboseMode:(bool) f_really{
  m_verbose = f_really;
}


@end
