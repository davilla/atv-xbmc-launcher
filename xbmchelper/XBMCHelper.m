//
//  XBMCHelper.m
//  xbmchelper
//
//  Created by Stephan Diederich on 11/12/08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "XBMCHelper.h"
#import "remotecontrolwrapper/AppleRemote.h"

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
@implementation XBMCHelper
- (id) init{
  if( ![super init] ){
    return nil;
  }
  mp_wrapper = nil;
  // capture remote
  mp_remote_control = [[AppleRemote alloc] initWithDelegate: self];
  [mp_remote_control startListening: self];

  return self;
}

- (void) dealloc{
  [mp_remote_control release];
  [mp_wrapper release];
  [super dealloc];
}

//----------------------------------------------------------------------------
- (void) sendRemoteButtonEvent: (RemoteControlEventIdentifier) event 
                   pressedDown: (BOOL) pressedDown 
                 remoteControl: (RemoteControl*) remoteControl 
{
  // NSLog(@"Button %d pressed down %d", event, pressedDown);
  if(m_verbose)
    NSLog(@"Button %d pressed down %d", event, pressedDown);
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
      else NSLog(@"Hold released"); 
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
