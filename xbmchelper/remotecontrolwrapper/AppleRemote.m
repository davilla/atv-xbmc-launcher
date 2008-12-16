/*****************************************************************************
 * RemoteControlWrapper.m
 * RemoteControlWrapper
 *
 * Created by Martin Kahr on 11.03.06 under a MIT-style license. 
 * Copyright (c) 2006 martinkahr.com. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a 
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 *****************************************************************************/

#import "AppleRemote.h"
#import "osdetection.h"

#import <mach/mach.h>
#import <mach/mach_error.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/hid/IOHIDKeys.h>

const char* AppleIRControllerName = "AppleIRController";
const char* AppleTVIRReceiverName = "AppleTVIRReceiver";
const NSTimeInterval SEND_UP_DELAY_TIME_INTERVAL=0.2; // used on atv >= 2.3 where we get no up event here
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
@implementation AppleRemote

//----------------------------------------------------------------------------
+ (const char*) remoteControlDeviceName {
  const char* ir_device_name;
  
  if (getHWVersion() == kOSXversion ) {
    // standard OSX box
    ir_device_name = AppleIRControllerName;
  } else {
    // AppleTV
    switch ( getOSVersion() ) {
      case kATV_1_00:
      case kATV_1_10:
      case kATV_2_00:
      case kATV_2_01:
      case kATV_2_02:
      case kATV_2_10:
      case kATV_2_20:
        ir_device_name = AppleIRControllerName;
        break;
        
      default:
      case kATV_2_30:
        ir_device_name = AppleTVIRReceiverName;
        break;
    }
  }
  
	return ir_device_name;
}

//----------------------------------------------------------------------------
- (void) setCookieMappingInDictionary: (NSMutableDictionary*) _cookieToButtonMapping {
  OS_Vers os_version;

  os_version = getOSVersion();
  if (getHWVersion() == kOSXversion ) {
    // standard OSX box
    if (os_version == kOSX_10_4) {
      // OSX 10.4.x
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlus]		forKey:@"14_12_11_6_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMinus]		forKey:@"14_13_11_6_"];		
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu]		forKey:@"14_7_6_14_7_6_"];			
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay]		forKey:@"14_8_6_14_8_6_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight]		forKey:@"14_9_6_14_9_6_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft]		forKey:@"14_10_6_14_10_6_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight_Hold]	forKey:@"14_6_4_2_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft_Hold]	forKey:@"14_6_3_2_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu_Hold]	forKey:@"14_6_14_6_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay_Hold]	forKey:@"18_14_6_18_14_6_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteControl_Switched]	forKey:@"19_"];	
    } else {
      // OSX 10.5.x Leopard or greater
      NSLog(@"Using key code for OSX OSX 10.5 Leopard");
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlus]		forKey:@"31_29_28_19_18_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMinus]		forKey:@"31_30_28_19_18_"];	
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu]		forKey:@"31_20_19_18_31_20_19_18_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay]		forKey:@"31_21_19_18_31_21_19_18_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight]		forKey:@"31_22_19_18_31_22_19_18_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft]		forKey:@"31_23_19_18_31_23_19_18_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight_Hold]	forKey:@"31_19_18_4_2_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft_Hold]	forKey:@"31_19_18_3_2_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu_Hold]	forKey:@"31_19_18_31_19_18_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay_Hold]	forKey:@"35_31_19_18_35_31_19_18_"];
      [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteControl_Switched]	forKey:@"19_"];			
    }
  } else {
    // AppleTV
    switch (os_version) {
      case kATV_1_00:
      case kATV_1_10:
      case kATV_2_00:
      case kATV_2_01:
      case kATV_2_02:
        // ATV 1.x, 2.0 -> 2.1
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlus]		forKey:@"14_12_11_6_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMinus]		forKey:@"14_13_11_6_"];		
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu]		forKey:@"14_7_6_14_7_6_"];			
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay]		forKey:@"14_8_6_14_8_6_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight]		forKey:@"14_9_6_14_9_6_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft]		forKey:@"14_10_6_14_10_6_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight_Hold]	forKey:@"14_6_4_2_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft_Hold]	forKey:@"14_6_3_2_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu_Hold]	forKey:@"14_6_14_6_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay_Hold]	forKey:@"18_14_6_18_14_6_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteControl_Switched]	forKey:@"19_"];	
        break;
      case kATV_2_10:
      case kATV_2_20:
        // ATV 1.x, 2.0 -> 2.2
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlus]		forKey:@"15_13_12_7_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMinus]		forKey:@"15_14_12_7_"];		
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu]		forKey:@"15_8_7_"];			
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay]		forKey:@"15_9_7_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight]		forKey:@"15_10_7_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft]		forKey:@"15_11_7_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight_Hold]	forKey:@"15_7_3_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft_Hold]	forKey:@"15_7_4_3_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu_Hold]	forKey:@"15_7_6_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay_Hold]	forKey:@"19_15_7_19_15_7_"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteControl_Switched]	forKey:@"19_"];	
        break;
      default:
      case kATV_2_30:
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlus]		forKey:@"80"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMinus]		forKey:@"48"];		
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu]		forKey:@"64"];			
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay]		forKey:@"32"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight]		forKey:@"96"];
        [_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft]		forKey:@"16"];
        //[_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonRight_Hold]	forKey:@"14_6_4_2_"];
        //[_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonLeft_Hold]	forKey:@"14_6_3_2_"];
        //[_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonMenu_Hold]	forKey:@"14_6_14_6_"];
        //[_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteButtonPlay_Hold]	forKey:@"18_14_6_18_14_6_"];
        //[_cookieToButtonMapping setObject:[NSNumber numberWithInt:kRemoteControl_Switched]	forKey:@"19_"];	
        break;
    }
  }
}

//----------------------------------------------------------------------------
- (BOOL) sendsEventForButtonIdentifier: (RemoteControlEventIdentifier) identifier {
  //let multiclickremotebehaviour send hold buttons for us on atv >= 2.3
  BOOL ret = TRUE;
  
  if (getHWVersion() == kATVversion ) {
    switch ( getOSVersion() ) {
      case kATV_1_00:
      case kATV_1_10:
      case kATV_2_00:
      case kATV_2_01:
      case kATV_2_02:
      case kATV_2_10:
      case kATV_2_20:
        break;
      default:
      case kATV_2_30:
        if(identifier == kRemoteButtonPlay_Hold ||  identifier == kRemoteButtonMenu_Hold) {
          ret = FALSE;
        }
    }
  }
  return ret;
}

#ifdef DEBUG
  //for now enable this in debug builds. 
  #define EXTREME_SENDREMOTEBUTTON_EVENT_DEBUGGING 1
#endif

//----------------------------------------------------------------------------
- (void) sendSimulatedUpEvent:(id) event {
#ifdef EXTREME_SENDREMOTEBUTTON_EVENT_DEBUGGING
  NSLog(@"Timer fired, sending up event type %i", [event intValue]);
#endif
  [super sendRemoteButtonEvent:[event intValue] pressedDown:NO];
  m_last_event = 0;
}

//----------------------------------------------------------------------------
- (void) sendRemoteButtonEvent: (RemoteControlEventIdentifier) event pressedDown: (BOOL) pressedDown {
  if( getHWVersion() == kATVversion && getOSVersion() >= 230 ){
    // on atv >=2.3 ir handling is a bit broken. we get only non-press events, and those all the time.
    //what we do here is to hide all those repeated events and just fire an UP event when the button changes or specified time elapsed
    if(!m_last_event){
#ifdef EXTREME_SENDREMOTEBUTTON_EVENT_DEBUGGING
      NSLog(@"First event of type %i", event);
#endif
      [super sendRemoteButtonEvent:event pressedDown:YES];
			[self performSelector:@selector(sendSimulatedUpEvent:) 
                 withObject:[NSNumber numberWithInt:event]
                 afterDelay:SEND_UP_DELAY_TIME_INTERVAL];      
    } else if( event != m_last_event){
#ifdef EXTREME_SENDREMOTEBUTTON_EVENT_DEBUGGING
      NSLog(@"Events changed. New of type %i", event);
      NSLog(@"Sending old up event first %i", m_last_event);
#endif
      //new event, send old up first and then new
      [super sendRemoteButtonEvent:m_last_event pressedDown:NO];
      [super sendRemoteButtonEvent:event pressedDown:YES];
    } else {
#ifdef EXTREME_SENDREMOTEBUTTON_EVENT_DEBUGGING
      NSLog(@"Again event of type %i. Resetting timer.", event);
#endif
      //same event button press again cancel any old and schedule a new timer
      [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendSimulatedUpEvent:) object:[NSNumber numberWithInt:event]];
			[self performSelector:@selector(sendSimulatedUpEvent:) 
                 withObject:[NSNumber numberWithInt:event]
                 afterDelay:SEND_UP_DELAY_TIME_INTERVAL];
    }
    m_last_event = event;    
  } else {
    if (pressedDown == NO && event == kRemoteButtonMenu_Hold) {
      // There is no seperate event for pressed down on menu hold. We are simulating that event here
      [super sendRemoteButtonEvent:event pressedDown:YES];
    }		
    [super sendRemoteButtonEvent:event pressedDown:pressedDown];
    
    if (pressedDown && (event == kRemoteButtonRight || event == kRemoteButtonLeft || event == kRemoteButtonPlay || event == kRemoteButtonMenu || event == kRemoteButtonPlay_Hold)) {
      // There is no seperate event when the button is being released. We are simulating that event here
      [super sendRemoteButtonEvent:event pressedDown:NO];
    }
  }
}

@end
